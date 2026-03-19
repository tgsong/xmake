using System.Runtime.InteropServices;

[DllImport("mathlib")]
static extern int add(int a, int b);

[DllImport("mathlib")]
static extern int multiply(int a, int b);

int sum = add(3, 4);
int product = multiply(5, 6);
Console.WriteLine($"add(3,4)={sum}");
Console.WriteLine($"multiply(5,6)={product}");
