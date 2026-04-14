using TestWidgetProvider.Com;
using Microsoft.Windows.Widgets.Providers;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Text.Json.Serialization;
using WinRT;

namespace TestWidgetProvider;

public static class Program
{
    public const string PipeName       = "TestWidgetProvider.d94hev71b6gse";
    public const string ActionPipeName = "TestWidgetProvider.actions.d94hev71b6gse";

    [DllImport("kernel32.dll")]
    static extern IntPtr GetConsoleWindow();

    [MTAThread]
    static void Main(string[] args)
    {
        if (args.Length == 0 || args[0] != "-RegisterProcessAsComServer")
        {
            Console.WriteLine("Not launched as COM server — exiting.");
            return;
        }

        ComWrappersSupport.InitializeComWrappers();

        Console.WriteLine("Registering Test Widget Provider...");
        ClassObject.Register(typeof(WidgetProvider).GUID, new WidgetProviderFactory<WidgetProvider>(), out uint cookie);
        Console.WriteLine($"Registered. Listening on pipe: {PipeName}");

        StartPipeServer();

        if (GetConsoleWindow() != IntPtr.Zero)
        {
            Console.WriteLine("Press ENTER to exit.");
            Console.ReadLine();
        }
        else
        {
            WidgetProvider.WidgetDeletedEvent.WaitOne();
        }

        ClassObject.Revoke(cookie);
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
