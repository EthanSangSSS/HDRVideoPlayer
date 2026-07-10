using System.Runtime.InteropServices;

namespace HDRVideoPlayer.Core.Metadata.MediaFoundation;

internal static class MediaFoundationInterop
{
    internal const int RpcEChangedMode = unchecked((int)0x80010106);
    internal const uint CoInitMultithreaded = 0;
    internal const uint MfVersion = 0x00020070;
    internal const uint MfStartupNoSocket = 0x1;
    internal const uint MfResolutionMediaSource = 0x1;

    [DllImport("ole32.dll", ExactSpelling = true)]
    internal static extern int CoInitializeEx(IntPtr reserved, uint coInit);

    [DllImport("ole32.dll", ExactSpelling = true)]
    internal static extern void CoUninitialize();

    [DllImport("mfplat.dll", ExactSpelling = true)]
    internal static extern int MFStartup(uint version, uint flags);

    [DllImport("mfplat.dll", ExactSpelling = true)]
    internal static extern int MFShutdown();

    [DllImport("mfplat.dll", ExactSpelling = true)]
    internal static extern int MFCreateSourceResolver(out IMFSourceResolver sourceResolver);
}

[ComImport]
[Guid("FBE5A32D-A497-4B61-BB85-97B1A848A6E3")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IMFSourceResolver
{
    [PreserveSig]
    int CreateObjectFromURL(
        [MarshalAs(UnmanagedType.LPWStr)] string url,
        uint flags,
        IntPtr properties,
        out MfObjectType objectType,
        [MarshalAs(UnmanagedType.IUnknown)] out object source);
}

internal enum MfObjectType
{
    Invalid,
    MediaSource,
    ByteStream
}

[ComImport]
[Guid("279A808D-AEC7-40C8-9C6B-A6B492C78A66")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IMFMediaSource
{
    [PreserveSig] int GetEvent(uint flags, IntPtr mediaEvent);
    [PreserveSig] int BeginGetEvent(IntPtr callback, IntPtr state);
    [PreserveSig] int EndGetEvent(IntPtr result, IntPtr mediaEvent);
    [PreserveSig] int QueueEvent(int eventType, in Guid extendedType, int status, IntPtr value);
    [PreserveSig] int GetCharacteristics(out uint characteristics);
    [PreserveSig] int CreatePresentationDescriptor(out IMFPresentationDescriptor descriptor);
    [PreserveSig] int Start(IntPtr descriptor, IntPtr timeFormat, IntPtr startPosition);
    [PreserveSig] int Stop();
    [PreserveSig] int Pause();
    [PreserveSig] int Shutdown();
}

[ComImport]
[Guid("2CD2D921-C447-44A7-A13C-4ADABFC247E3")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IMFAttributes
{
    [PreserveSig] int GetItem(in Guid key, IntPtr value);
    [PreserveSig] int GetItemType(in Guid key, out int type);
    [PreserveSig] int CompareItem(in Guid key, IntPtr value, out int result);
    [PreserveSig] int Compare(IMFAttributes theirs, int matchType, out int result);
    [PreserveSig] int GetUINT32(in Guid key, out uint value);
    [PreserveSig] int GetUINT64(in Guid key, out ulong value);
    [PreserveSig] int GetDouble(in Guid key, out double value);
    [PreserveSig] int GetGUID(in Guid key, out Guid value);
    [PreserveSig] int GetStringLength(in Guid key, out uint length);
    [PreserveSig] int GetString(in Guid key, IntPtr value, uint bufferSize, IntPtr length);
    [PreserveSig] int GetAllocatedString(in Guid key, IntPtr value, IntPtr length);
    [PreserveSig] int GetBlobSize(in Guid key, out uint size);
    [PreserveSig] int GetBlob(in Guid key, IntPtr buffer, uint bufferSize, IntPtr blobSize);
    [PreserveSig] int GetAllocatedBlob(in Guid key, IntPtr buffer, IntPtr size);
    [PreserveSig] int GetUnknown(in Guid key, in Guid interfaceId, IntPtr value);
    [PreserveSig] int SetItem(in Guid key, IntPtr value);
    [PreserveSig] int DeleteItem(in Guid key);
    [PreserveSig] int DeleteAllItems();
    [PreserveSig] int SetUINT32(in Guid key, uint value);
    [PreserveSig] int SetUINT64(in Guid key, ulong value);
    [PreserveSig] int SetDouble(in Guid key, double value);
    [PreserveSig] int SetGUID(in Guid key, in Guid value);
    [PreserveSig] int SetString(in Guid key, IntPtr value);
    [PreserveSig] int SetBlob(in Guid key, IntPtr buffer, uint bufferSize);
    [PreserveSig] int SetUnknown(in Guid key, IntPtr unknown);
    [PreserveSig] int LockStore();
    [PreserveSig] int UnlockStore();
    [PreserveSig] int GetCount(out uint count);
    [PreserveSig] int GetItemByIndex(uint index, out Guid key, IntPtr value);
    [PreserveSig] int CopyAllItems(IMFAttributes destination);
}

[ComImport]
[Guid("03CB2711-24D7-4DB6-A17F-F3A7A479A536")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IMFPresentationDescriptor : IMFAttributes
{
    [PreserveSig] int GetStreamDescriptorCount(out uint count);
    [PreserveSig] int GetStreamDescriptorByIndex(uint index, out int selected, out IMFStreamDescriptor descriptor);
}

[ComImport]
[Guid("56C03D9C-9DBB-45F5-AB4B-D80F47C05938")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IMFStreamDescriptor : IMFAttributes
{
    [PreserveSig] int GetStreamIdentifier(out uint identifier);
    [PreserveSig] int GetMediaTypeHandler(out IMFMediaTypeHandler handler);
}

[ComImport]
[Guid("E93DCF6C-4B07-4E1E-8123-AA16ED6EADF5")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IMFMediaTypeHandler
{
    [PreserveSig] int IsMediaTypeSupported(IMFMediaType mediaType, IntPtr closestMatch);
    [PreserveSig] int GetMediaTypeCount(out uint count);
    [PreserveSig] int GetMediaTypeByIndex(uint index, out IMFMediaType mediaType);
    [PreserveSig] int SetCurrentMediaType(IMFMediaType mediaType);
    [PreserveSig] int GetCurrentMediaType(out IMFMediaType mediaType);
    [PreserveSig] int GetMajorType(out Guid majorType);
}

[ComImport]
[Guid("44AE0FA8-EA31-4109-8D2E-4CAE4997C555")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IMFMediaType : IMFAttributes
{
}
