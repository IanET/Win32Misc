using Microsoft.Windows.Widgets.Providers;
using System.Runtime.InteropServices;

namespace HelloWidgetProvider;

// CLSID must match the ClassId in Package.appxmanifest
[Guid("f8444433-3aa5-42a4-a496-5c2b36f3b3eb")]
internal partial class WidgetProvider : IWidgetProvider
{

    // Adaptive Card template — just shows "Hello World!"
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

    private static readonly Dictionary<string, bool> _runningWidgets = new();
    private static readonly ManualResetEvent _emptyEvent = new(false);

    public WidgetProvider()
    {
        // Re-register any widgets that were running before we started (e.g. after a crash/reboot)
        foreach (var info in WidgetManager.GetDefault().GetWidgetInfos())
        {
            _runningWidgets.TryAdd(info.WidgetContext.Id, false);
        }
    }

    public static ManualResetEvent EmptyWidgetListEvent => _emptyEvent;

    // Called when the user pins the widget
    public void CreateWidget(WidgetContext widgetContext)
    {
        _runningWidgets[widgetContext.Id] = false;
        SendUpdate(widgetContext.Id);
    }

    // Called when the user unpins the widget
    public void DeleteWidget(string widgetId, string customState)
    {
        _runningWidgets.Remove(widgetId);
        if (_runningWidgets.Count == 0)
            _emptyEvent.Set();
    }

    // Called when the widget host wants fresh content
    public void Activate(WidgetContext widgetContext)
    {
        _runningWidgets[widgetContext.Id] = true;
        SendUpdate(widgetContext.Id);
    }

    // Called when the widget host stops needing updates
    public void Deactivate(string widgetId)
    {
        if (_runningWidgets.ContainsKey(widgetId))
            _runningWidgets[widgetId] = false;
    }

    // Called when the widget is resized
    public void OnWidgetContextChanged(WidgetContextChangedArgs contextChangedArgs)
    {
        SendUpdate(contextChangedArgs.WidgetContext.Id);
    }

    // Called when the user interacts with a button/action on the widget
    public void OnActionInvoked(WidgetActionInvokedArgs actionInvokedArgs)
    {
        // Hello World has no interactive actions
    }

    private static void SendUpdate(string widgetId)
    {
        var options = new WidgetUpdateRequestOptions(widgetId)
        {
            Template = HelloTemplate,
            Data = "{}",
        };
        WidgetManager.GetDefault().UpdateWidget(options);
    }
}
