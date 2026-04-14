using Microsoft.Windows.Widgets.Providers;
using System.Runtime.InteropServices;

namespace HelloWidgetProvider;

// CLSID must match the ClassId in Package.appxmanifest
[Guid("f8444433-3aa5-42a4-a496-5c2b36f3b3eb")]
internal partial class WidgetProvider : IWidgetProvider
{
    private const string HelloTemplate = """
        {
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "type": "AdaptiveCard",
            "version": "1.5",
            "body": [
                {
                    "type": "TextBlock",
                    "text": "Hello World!",
                    "size": "large",
                    "weight": "bolder",
                    "wrap": true
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

    private static void SendUpdate()
    {
        if (_widgetId is null) return;
        WidgetManager.GetDefault().UpdateWidget(new WidgetUpdateRequestOptions(_widgetId)
        {
            Template = HelloTemplate,
            Data = "{}",
        });
    }
}
