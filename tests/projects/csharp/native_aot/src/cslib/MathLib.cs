using System.Runtime.InteropServices;

public static class MathLib {
    [UnmanagedCallersOnly(EntryPoint = "cs_add")]
    public static int Add(int a, int b) => a + b;

    [UnmanagedCallersOnly(EntryPoint = "cs_multiply")]
    public static int Multiply(int a, int b) => a * b;
}
