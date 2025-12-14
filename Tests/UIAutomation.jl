import .W32: DWORD, LPVOID, USHORT, @L_str

const Ole32 = "Ole32"

const CLSID = GUID
const REFCLSID = Ptr{CLSID}
const LPUNKNOWN = Ptr{IUnknown}
const PATTERNID = Cint
const TreeScope = Cint
const VARTYPE = W32.USHORT
const PROPERTYID = Cint
const OLECHAR = WCHAR
const BSTR = Ptr{OLECHAR}

const CLSCTX_INPROC_SERVER = 0x1
const UIA_TextPatternId = 10014
const TreeScope_Children = 0x02
const TreeScope_Descendants = 0x04
const VARTYPE_I4 = 3
const UIA_ControlTypePropertyId = LONG(30003)
const UIA_DocumentControlTypeId = LONG(50030)
const UIA_WindowControlTypeId = LONG(50032)
const VT_I4 = 3
# const E_INVALDARG = 0x80070057

const CLSID_CUIAutomation = GUID(0xff48dba4, 0x60ef, 0x4201, 0xaa87, 0x54103eef594e)
const IID_IUIAutomation = GUID(0x30cbe57d, 0xd9d0, 0x452a, 0xab13, 0x7ac5ac4825ee)
const IID_IUIAutomationTextPattern = GUID(0x32eba289, 0x3583, 0x42c9, 0x9c59, 0x3b6d9a1e9b6a)

CoInitialize(pvReserved) = @ccall Ole32.CoInitialize(pvReserved::Ptr{C_NULL})::HRESULT
CoCreateInstance(rclsid, pUnkOuter, dwClsContext, riid, ppv) = @ccall Ole32.CoCreateInstance(rclsid::REFCLSID, pUnkOuter::LPUNKNOWN, dwClsContext::DWORD, riid::REFIID, ppv::LPVOID)::HRESULT

@kwdef struct VARIANT
    vt::VARTYPE = 0
    wReserved1::USHORT = 0
    wReserved2::USHORT = 0
    wReserved3::USHORT = 0
    pad::NTuple{16, UInt8} = zeros(UInt8, 16) |> Tuple
end

# TODO: Implement VARIANT

@kwdef struct VARIANT_I4
    vt::VARTYPE = VARTYPE_I4
    wReserved1::USHORT = 0
    wReserved2::USHORT = 0
    wReserved3::USHORT = 0
    intVal::Cint = 0
    pad::NTuple{12, UInt8} = zeros(UInt8, 12) |> Tuple
end

@interface IUIAutomationCondition begin
    @inherit IUnknown
end

@interface IUIAutomationPropertyCondition begin
    @inherit IUIAutomationCondition
    get_PropertyId(this::Ptr{IUIAutomationPropertyCondition}, propertyId::Ptr{PROPERTYID})::HRESULT
    get_PropertyValue(this::Ptr{IUIAutomationPropertyCondition}, value::Ptr{VARIANT})::HRESULT
    get_PropertyConditionFlags(this::Ptr{IUIAutomationPropertyCondition}, flags::Ptr{Cint})::HRESULT
end

@interface IUIAutomationTextRange begin
    @inherit IUnknown
    Clone::Ptr{Cvoid}
    Compare::Ptr{Cvoid}
    CompareEndpoints::Ptr{Cvoid}
    ExpandToEnclosingUnit::Ptr{Cvoid}
    FindAttribute::Ptr{Cvoid}
    FindText::Ptr{Cvoid}
    GetAttributeValue::Ptr{Cvoid}
    GetBoundingRectangles::Ptr{Cvoid}
    GetEnclosingElement::Ptr{Cvoid}
    GetText(this::Ptr{IUIAutomationTextRange}, maxLength::Cint, text::Ptr{BSTR})::HRESULT
    Move::Ptr{Cvoid}
    MoveEndpointByUnit::Ptr{Cvoid}
    MoveEndpointByRange::Ptr{Cvoid}
    Select::Ptr{Cvoid}
    AddToSelection::Ptr{Cvoid}
    RemoveFromSelection::Ptr{Cvoid}
    ScrollIntoView::Ptr{Cvoid}
    GetChildren::Ptr{Cvoid}
end

@interface IUIAutomationTextPattern begin
    @inherit IUnknown
    RangeFromPoint::Ptr{Cvoid}
    RangeFromChild::Ptr{Cvoid}
    GetSelection::Ptr{Cvoid}
    GetVisibleRanges::Ptr{Cvoid}
    get_DocumentRange(this::Ptr{IUIAutomationTextPattern}, range::Ptr{Ptr{IUIAutomationTextRange}})::HRESULT
    get_SupportedTextSelection::Ptr{Cvoid}
end

@interface IUIAutomationElement begin
    @inherit IUnknown
    SetFocus::Ptr{Cvoid}
    GetRuntimeId::Ptr{Cvoid}
    FindFirst(this::Ptr{IUIAutomationElement}, scope::TreeScope, condition::Ptr{IUIAutomationCondition}, element::Ptr{Ptr{IUIAutomationElement}})::HRESULT
    FindAll::Ptr{Cvoid}
    FindFirstBuildCache::Ptr{Cvoid}
    FindAllBuildCache::Ptr{Cvoid}
    BuildUpdatedCache::Ptr{Cvoid}
    GetCurrentPropertyValue::Ptr{Cvoid}
    GetCurrentPropertyValueEx::Ptr{Cvoid}
    GetCachedPropertyValue::Ptr{Cvoid}
    GetCachedPropertyValueEx::Ptr{Cvoid}
    GetCurrentPatternAs(this::Ptr{IUIAutomationElement}, patternId::PATTERNID, interfaceId::REFIID, patternObject::Ptr{Ptr{Cvoid}})::HRESULT
    GetCachedPatternAs::Ptr{Cvoid}
    GetCurrentPattern::Ptr{Cvoid}
    GetCachedPattern::Ptr{Cvoid}
    GetCachedParent::Ptr{Cvoid}
    GetCachedChildren::Ptr{Cvoid}
    get_CurrentProcessId::Ptr{Cvoid}
    get_CurrentControlType::Ptr{Cvoid}
    get_CurrentLocalizedControlType::Ptr{Cvoid}
    get_CurrentName::Ptr{Cvoid}
    get_CurrentAcceleratorKey::Ptr{Cvoid}
    get_CurrentAccessKey::Ptr{Cvoid}
    get_CurrentHasKeyboardFocus::Ptr{Cvoid}
    get_CurrentIsKeyboardFocusable::Ptr{Cvoid}
    get_CurrentIsEnabled::Ptr{Cvoid}
    get_CurrentAutomationId::Ptr{Cvoid}
    get_CurrentClassName::Ptr{Cvoid}
    get_CurrentHelpText::Ptr{Cvoid}
    get_CurrentCulture::Ptr{Cvoid}
    get_CurrentIsControlElement::Ptr{Cvoid}
    get_CurrentIsContentElement::Ptr{Cvoid}
    get_CurrentIsPassword::Ptr{Cvoid}
    get_CurrentNativeWindowHandle::Ptr{Cvoid}
    get_CurrentItemType::Ptr{Cvoid}
    get_CurrentIsOffscreen::Ptr{Cvoid}
    get_CurrentOrientation::Ptr{Cvoid}
    get_CurrentFrameworkId::Ptr{Cvoid}
    get_CurrentIsRequiredForForm::Ptr{Cvoid}
    get_CurrentItemStatus::Ptr{Cvoid}
    get_CurrentBoundingRectangle::Ptr{Cvoid}
    get_CurrentLabeledBy::Ptr{Cvoid}
    get_CurrentAriaRole::Ptr{Cvoid}
    get_CurrentAriaProperties::Ptr{Cvoid}
    get_CurrentIsDataValidForForm::Ptr{Cvoid}
    get_CurrentControllerFor::Ptr{Cvoid}
    get_CurrentDescribedBy::Ptr{Cvoid}
    get_CurrentFlowsTo::Ptr{Cvoid}
    get_CurrentProviderDescription::Ptr{Cvoid}
    get_CachedProcessId::Ptr{Cvoid}
    get_CachedControlType::Ptr{Cvoid}
    get_CachedLocalizedControlType::Ptr{Cvoid}
    get_CachedName::Ptr{Cvoid}
    get_CachedAcceleratorKey::Ptr{Cvoid}
    get_CachedAccessKey::Ptr{Cvoid}
    get_CachedHasKeyboardFocus::Ptr{Cvoid}
    get_CachedIsKeyboardFocusable::Ptr{Cvoid}
    get_CachedIsEnabled::Ptr{Cvoid}
    get_CachedAutomationId::Ptr{Cvoid}
    get_CachedClassName::Ptr{Cvoid}
    get_CachedHelpText::Ptr{Cvoid}
    get_CachedCulture::Ptr{Cvoid}
    get_CachedIsControlElement::Ptr{Cvoid}
    get_CachedIsContentElement::Ptr{Cvoid}
    get_CachedIsPassword::Ptr{Cvoid}
    get_CachedNativeWindowHandle::Ptr{Cvoid}
    get_CachedItemType::Ptr{Cvoid}
    get_CachedIsOffscreen::Ptr{Cvoid}
    get_CachedOrientation::Ptr{Cvoid}
    get_CachedFrameworkId::Ptr{Cvoid}
    get_CachedIsRequiredForForm::Ptr{Cvoid}
    get_CachedItemStatus::Ptr{Cvoid}
    get_CachedBoundingRectangle::Ptr{Cvoid}
    get_CachedLabeledBy::Ptr{Cvoid}
    get_CachedAriaRole::Ptr{Cvoid}
    get_CachedAriaProperties::Ptr{Cvoid}
    get_CachedIsDataValidForForm::Ptr{Cvoid}
    get_CachedControllerFor::Ptr{Cvoid}
    get_CachedDescribedBy::Ptr{Cvoid}
    get_CachedFlowsTo::Ptr{Cvoid}
    get_CachedProviderDescription::Ptr{Cvoid}
    GetClickablePoint::Ptr{Cvoid}
end

@interface IUIAutomation begin
    @inherit IUnknown
    CompareElements::Ptr{Cvoid}
    CompareRuntimeIds::Ptr{Cvoid}
    GetRootElement::Ptr{Cvoid}
    ElementFromHandle(this::Ptr{IUIAutomation}, hwnd::HWND, element::Ptr{Ptr{IUIAutomationElement}})::HRESULT
    ElementFromPoint::Ptr{Cvoid}
    GetFocusedElement::Ptr{Cvoid}
    GetRootElementBuildCache::Ptr{Cvoid}
    ElementFromHandleBuildCache::Ptr{Cvoid}
    ElementFromPointBuildCache::Ptr{Cvoid}
    GetFocusedElementBuildCache::Ptr{Cvoid}
    CreateTreeWalker::Ptr{Cvoid}
    get_ControlViewWalker::Ptr{Cvoid}
    get_ContentViewWalker::Ptr{Cvoid}
    get_RawViewWalker::Ptr{Cvoid}
    get_RawViewCondition::Ptr{Cvoid}
    get_ControlViewCondition::Ptr{Cvoid}
    get_ContentViewCondition::Ptr{Cvoid}
    CreateCacheRequest::Ptr{Cvoid}
    CreateTrueCondition::Ptr{Cvoid}
    CreateFalseCondition::Ptr{Cvoid}
    CreatePropertyCondition(this::Ptr{IUIAutomation}, propertyId::PROPERTYID, value::VARIANT_I4, condition::Ptr{Ptr{IUIAutomationPropertyCondition}})::HRESULT
    CreatePropertyConditionEx::Ptr{Cvoid}
    CreateAndCondition::Ptr{Cvoid}
    CreateAndConditionFromArray::Ptr{Cvoid}
    CreateAndConditionFromNativeArray::Ptr{Cvoid}
    CreateOrCondition::Ptr{Cvoid}
    CreateOrConditionFromArray::Ptr{Cvoid}
    CreateOrConditionFromNativeArray::Ptr{Cvoid}
    CreateNotCondition::Ptr{Cvoid}
    AddAutomationEventHandler::Ptr{Cvoid}
    RemoveAutomationEventHandler::Ptr{Cvoid}
    AddPropertyChangedEventHandler::Ptr{Cvoid}
    RemovePropertyChangedEventHandler::Ptr{Cvoid}
    AddStructureChangedEventHandler::Ptr{Cvoid}
    RemoveStructureChangedEventHandler::Ptr{Cvoid}
    AddFocusChangedEventHandler::Ptr{Cvoid}
    RemoveFocusChangedEventHandler::Ptr{Cvoid}
    RemoveAllEventHandlers::Ptr{Cvoid}
    IntNativeArrayToSafeArray::Ptr{Cvoid}
    IntSafeArrayToNativeArray::Ptr{Cvoid}
    RectToVariant::Ptr{Cvoid}
    VariantToRect::Ptr{Cvoid}
    SafeArrayToRectNativeArray::Ptr{Cvoid}
    CreateProxyFactoryEntry::Ptr{Cvoid}
    get_ProxyFactoryMapping::Ptr{Cvoid}
    GetPropertyProgrammaticName::Ptr{Cvoid}
    GetPatternProgrammaticName::Ptr{Cvoid}
    PollForPotentialSupportedPatterns::Ptr{Cvoid}
    PollForPotentialSupportedProperties::Ptr{Cvoid}
    CheckNotSupported::Ptr{Cvoid}
    get_ReservedNotSupportedValue::Ptr{Cvoid}
    get_ReservedMixedAttributeValue::Ptr{Cvoid}
    ElementFromIAccessible::Ptr{Cvoid}
    ElementFromIAccessibleBuildCache::Ptr{Cvoid}
end
