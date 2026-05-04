using TestWidgetProvider.Com;
using Microsoft.Windows.Widgets.Providers;
using System.Diagnostics;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using WinRT;

namespace TestWidgetProvider;

public static class Program
{
    public const string PipeName       = "TestWidgetProvider.d94hev71b6gse_to_provider";
    public const string ActionPipeName = "TestWidgetProvider.d94hev71b6gse_from_provider";

    static readonly string ClientDir   = Path.Combine(AppContext.BaseDirectory, "Client");
    static readonly string JuliaScript = Path.Combine(ClientDir, "TaskListGadget.app.jl");

    [MTAThread]
    static void Main(string[] args)
    {
        Console.SetOut(new DebugWriter());

        if (args.Length == 0 || args[0] != "-RegisterProcessAsComServer")
        {
            Console.WriteLine("Not launched as COM server — exiting.");
            return;
        }

        var julia = LaunchJuliaClient();

        AppDomain.CurrentDomain.ProcessExit += (_, _) =>
        {
            try { julia?.Kill(entireProcessTree: true); } catch { }
        };

        ComWrappersSupport.InitializeComWrappers();

        Console.WriteLine("Registering Task Switcher Widget Provider...");
        ClassObject.Register(typeof(WidgetProvider).GUID, new WidgetProviderFactory<WidgetProvider>(), out uint cookie);
        Console.WriteLine($"Registered. Listening on pipe: {PipeName}");

        StartPipeServer();

        Thread.Sleep(Timeout.Infinite);
    }

    static Process? LaunchJuliaClient()
    {
        try
        {
            var julia = Process.Start(new ProcessStartInfo
            {
                FileName        = "julia.exe",
                Arguments       = $"--project=\"{ClientDir}\" \"{JuliaScript}\"",
                UseShellExecute = false,
                CreateNoWindow  = true,
            });
            Console.WriteLine(julia is not null
                ? $"Julia client started (PID {julia.Id})"
                : "Julia client process was null");
            return julia;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to launch Julia client: {ex.Message}");
            return null;
        }
    }

    static void StartPipeServer()
    {
        new Thread(() =>
        {
            while (true)
            {
                using var pipe = new NamedPipeServerStream(PipeName, PipeDirection.In);
                pipe.WaitForConnection();
                using var reader = new StreamReader(pipe);
                while (reader.ReadLine() is string line)
                {
                    try
                    {
                        var msg = JsonSerializer.Deserialize<PipeMessage>(line);
                        if (msg is not null)
                        {
                            Console.WriteLine($"Received pipe message: length={line.Length}");
                            WidgetProvider.PipeUpdate(msg.Template, msg.Data);
                        }
                    }
                    catch (JsonException ex)
                    {
                        Console.WriteLine($"Invalid pipe message: {ex.Message}");
                    }
                }
            }
        }) { IsBackground = true }.Start();
    }
}

record PipeMessage(
    [property: JsonPropertyName("template")] string? Template,
    [property: JsonPropertyName("data")]     string? Data
);

class DebugWriter : TextWriter
{
    public override Encoding Encoding => Encoding.Unicode;

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    static extern void OutputDebugString(string lpOutputString);

    public override void WriteLine(string? value) => OutputDebugString((value ?? "") + "\n");
    public override void Write(string? value)     => OutputDebugString(value ?? "");
}
