using HelloWidgetProvider.Com;
using Microsoft.Windows.Widgets.Providers;
using System.Runtime.InteropServices;
using WinRT;

namespace HelloWidgetProvider;

public static class Program
{
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

        Console.WriteLine("Registering Hello World Widget Provider...");
        ClassObject.Register(typeof(WidgetProvider).GUID, new WidgetProviderFactory<WidgetProvider>(), out uint cookie);
        Console.WriteLine("Registered.");

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
}