using Microsoft.Windows.Widgets.Providers;
using System.Runtime.InteropServices;

namespace HelloWidgetProvider;

// CLSID must match the ClassId in Package.appxmanifest
[Guid("f8444433-3aa5-42a4-a496-5c2b36f3b3eb")]
internal partial class WidgetProvider : IWidgetProvider
{
    private const string HelloTemplate = """
        {
            "type":"AdaptiveCard",
            "version":"1.5",
            "body":[
                {
                    "type":"TextBlock",
                    "text":"Loading...",
                    "size":"small"
                }
            ]
        }
    """;

    private static string? _widgetId;
    private static string _currentTemplate = HelloTemplate;
    private static string _currentData = "{}";
    private static readonly WidgetManager _widgetManager = WidgetManager.GetDefault();
    public static readonly ManualResetEvent WidgetDeletedEvent = new(false);

    public WidgetProvider()
    {
        // Recover widget ID if we were restarted (e.g. after a crash/reboot)
        _widgetId = _widgetManager.GetWidgetIds().FirstOrDefault();
    }

    public void CreateWidget(WidgetContext widgetContext)
    {
        _widgetId = widgetContext.Id;
        SendUpdate();
    }

    public void DeleteWidget(string widgetId, string customState)
    {
        _widgetId = null;
        WidgetDeletedEvent.Set();
    }

    public void Activate(WidgetContext _) => SendUpdate();

    public void Deactivate(string _) { }

    public void OnWidgetContextChanged(WidgetContextChangedArgs _) => SendUpdate();

    public void OnActionInvoked(WidgetActionInvokedArgs _) { }

    // Called from the named pipe server — omit template or data to keep the cached value
    public static void PipeUpdate(string? template, string? data)
    {
        // Console.WriteLine($"PipeUpdate: widgetId={_widgetId ?? "null"} template={(template is null ? "null" : $"{template.Length} chars")} data={data ?? "null"}");
        // Console.WriteLine($"Template: {(template ?? "null")}");
        // Console.WriteLine($"Data: {(data ?? "null")}");

        if (template is not null) _currentTemplate = template;
        if (data is not null) _currentData = data;
        if (_widgetId is null)
        {
            Console.WriteLine("PipeUpdate: no widget ID, skipping.");
            return;
        }
        var options = new WidgetUpdateRequestOptions(_widgetId);
        if (template is not null) options.Template = template;
        if (data is not null) options.Data = data;
        _widgetManager.UpdateWidget(options);
        Console.WriteLine("PipeUpdate: UpdateWidget called.");
    }

    private static void SendUpdate()
    {
        if (_widgetId is null) return;
        _widgetManager.UpdateWidget(new WidgetUpdateRequestOptions(_widgetId)
        {
            Template = _currentTemplate,
            Data = _currentData,
        });
    }
}
