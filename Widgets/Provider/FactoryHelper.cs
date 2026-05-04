using Microsoft.Windows.Widgets.Providers;
using System.Runtime.InteropServices;
using WinRT;

namespace TestWidgetProvider.Com;

static class Guids
{
    public const string IClassFactory = "00000001-0000-0000-C000-000000000046";
    public const string IUnknown      = "00000000-0000-0000-C000-000000000046";
}

[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid(Guids.IClassFactory)]
internal interface IClassFactory
{
    [PreserveSig] int CreateInstance(IntPtr pUnkOuter, ref Guid riid, out IntPtr ppvObject);
    [PreserveSig] int LockServer(bool fLock);
}

static class ClassObject
{
    public static void Register(Guid clsid, object pUnk, out uint cookie)
    {
        int result = CoRegisterClassObject(clsid, pUnk, 0x4, 0x1, out cookie);
        if (result != 0) Marshal.ThrowExceptionForHR(result);
    }

    public static void Revoke(uint cookie) => CoRevokeClassObject(cookie);

    [DllImport("ole32.dll")]
    private static extern int CoRegisterClassObject(
        [MarshalAs(UnmanagedType.LPStruct)] Guid rclsid,
        [MarshalAs(UnmanagedType.IUnknown)] object pUnk,
        uint dwClsContext, uint flags, out uint lpdwRegister);

    [DllImport("ole32.dll")]
    private static extern int CoRevokeClassObject(uint dwRegister);
}

internal class WidgetProviderFactory<T> : IClassFactory
    where T : IWidgetProvider, new()
{
    private const int CLASS_E_NOAGGREGATION = -2147221232;
    private const int E_NOINTERFACE        = -2147467262;

    public int CreateInstance(IntPtr pUnkOuter, ref Guid riid, out IntPtr ppvObject)
    {
        ppvObject = IntPtr.Zero;
        if (pUnkOuter != IntPtr.Zero)
            Marshal.ThrowExceptionForHR(CLASS_E_NOAGGREGATION);

        if (riid == typeof(T).GUID || riid == Guid.Parse(Guids.IUnknown))
            ppvObject = MarshalInspectable<IWidgetProvider>.FromManaged(new T());
        else
            Marshal.ThrowExceptionForHR(E_NOINTERFACE);

        return 0;
    }

    public int LockServer(bool fLock) => 0;
}