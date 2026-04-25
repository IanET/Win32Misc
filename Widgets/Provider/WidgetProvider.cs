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
                    "text":"...",
                    "size":"small"
                }
            ]
        }
    """;

    private static string? _widgetId;
    private static string? _cachedTemplate;
    private static string? _cachedData;

    public WidgetProvider()
    {
        RecoverRunningWidgets();
    }

    private static void RecoverRunningWidgets()
    {
        var infos = WidgetManager.GetDefault().GetWidgetInfos();
        foreach (var info in infos)
        {
            var id = info.WidgetContext.Id;
            if (_widgetId is null)
            {
                _widgetId       = id;
                _cachedTemplate = string.IsNullOrEmpty(info.Template) ? null : info.Template;
                _cachedData     = string.IsNullOrEmpty(info.Data)     ? null : info.Data;
                Console.WriteLine($"Recovered widget ID: {_widgetId}");
            }
            else
            {
                // More widgets than we expect — delete extras
                WidgetManager.GetDefault().DeleteWidget(id);
                Console.WriteLine($"Deleted unexpected widget ID: {id}");
            }
        }
    }

    public void CreateWidget(WidgetContext widgetContext)
    {
        _widgetId = widgetContext.Id;
        SendUpdate();
        var size = widgetContext.Size.ToString();
        Console.WriteLine($"Widget created with ID: {_widgetId}, size={size}");
        SendEvent(new { type = "Create", size });
    }

    public void DeleteWidget(string widgetId, string customState)
    {
        _widgetId = null;
        Console.WriteLine($"Widget deleted with ID: {widgetId}, customState: {customState}");
        WidgetManager.GetDefault().DeleteWidget(widgetId);
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

    // Called from the named pipe server — caches and applies template/data from Julia
    public static void PipeUpdate(string? template, string? data)
    {
        if (_widgetId is null) return;
        if (template is not null) _cachedTemplate = template;
        if (data    is not null) _cachedData      = data;
        var options = new WidgetUpdateRequestOptions(_widgetId);
        if (template is not null) options.Template = template;
        if (data     is not null) options.Data     = data;
        Console.WriteLine($"PipeUpdate: _widgetId={_widgetId}, template={template is not null}, data={data is not null}");
        WidgetManager.GetDefault().UpdateWidget(options);
    }

    private static void SendUpdate()
    {
        if (_widgetId is null) return;
        WidgetManager.GetDefault().UpdateWidget(new WidgetUpdateRequestOptions(_widgetId)
        {
            Template = _cachedTemplate ?? DefaultTemplate,
            Data     = _cachedData     ?? "{}",
        });
    }
}
