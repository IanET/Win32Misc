using Microsoft.Windows.Widgets.Providers;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Text.Json;

namespace TestWidgetProvider;

// CLSID must match the ClassId in Package.appxmanifest
[Guid("f8444433-3aa5-42a4-a496-5c2b36f3b3eb")]
internal partial class WidgetProvider : IWidgetProvider
{
    private const string DefaultTemplate = """
        {
            "type":"AdaptiveCard",
            "version":"1.5",
            "body":[
                {
                    "type":"TextBlock",
                    "text":"Ready",
                    "size":"small"
                }
            ]
        }
    """;

    private static string? _widgetId;
    public static readonly ManualResetEvent WidgetDeletedEvent = new(false);

    public WidgetProvider()
    {
        // Recover widget ID if we were restarted (e.g. after a crash/reboot)
        _widgetId = WidgetManager.GetDefault().GetWidgetIds().FirstOrDefault();
    }

    public void CreateWidget(WidgetContext widgetContext)
    {
        _widgetId = widgetContext.Id;
        SendUpdate();
        Console.WriteLine($"Widget created with ID: {_widgetId}");
    }

    public void DeleteWidget(string widgetId, string customState)
    {
        _widgetId = null;
        WidgetDeletedEvent.Set();
        Console.WriteLine($"Widget deleted with ID: {widgetId}, customState: {customState}");
    }

    public void Activate(WidgetContext widgetContext)
    {
        var size = widgetContext.Size.ToString();
        Console.WriteLine($"Widget activated, size={size} (raw={widgetContext.Size})");
        SendEvent(new { type = "Activate", size });
    }

    public void Deactivate(string _)
    {
        Console.WriteLine("Widget deactivated");
        SendEvent(new { type = "Deactivate" });
    }

    public void OnWidgetContextChanged(WidgetContextChangedArgs args)
    {
        SendUpdate();
        SendEvent(new { type = "OnWidgetContextChanged", size = args.WidgetContext.Size.ToString() });
    }

    public void OnActionInvoked(WidgetActionInvokedArgs args)
    {
        var verb = args.Verb;
        // Acknowledge immediately so the host dismisses the spinner
        if (_widgetId is not null)
            WidgetManager.GetDefault().UpdateWidget(new WidgetUpdateRequestOptions(_widgetId));
        SendEvent(new { type = "OnActionInvoked", verb });
    }

    private static void SendEvent(object evt)
    {
        Task.Run(() =>
        {
            try
            {
                using var pipe = new NamedPipeClientStream(".", Program.ActionPipeName, PipeDirection.Out);
                pipe.Connect(1000);
                using var writer = new StreamWriter(pipe) { AutoFlush = true };
                writer.WriteLine(JsonSerializer.Serialize(evt));
                Console.WriteLine($"Event sent: {JsonSerializer.Serialize(evt)}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Event pipe: {ex.Message}");
            }
        });
    }

    // Called from the named pipe server — omit template or data to keep the cached value
    public static void PipeUpdate(string? template, string? data)
    {
        if (_widgetId is null) return;
        var options = new WidgetUpdateRequestOptions(_widgetId);
        // if (template is null) Console.WriteLine("Updating widget with cached template");
        if (template is not null) options.Template = template;
        // if (data is null) Console.WriteLine("Updating widget with cached data");
        if (data is not null) options.Data = data;
        WidgetManager.GetDefault().UpdateWidget(options);
    }

    private static void SendUpdate()
    {
        if (_widgetId is null) return;
        WidgetManager.GetDefault().UpdateWidget(new WidgetUpdateRequestOptions(_widgetId)
        {
            Template = DefaultTemplate,
            Data = "{}",
        });
    }
}
