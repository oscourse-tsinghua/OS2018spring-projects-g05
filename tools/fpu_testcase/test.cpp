#include <cmath>
#include <cstdio>
int main(){
	double x, y;
	printf("input A and B please, note A must be positive:\n");
	scanf("%f%f", &x, &y);
	printf("Abs A is %f\n", fabs(x));
	printf("Neg B is %f\n", -y);
	printf("A + B is %f\n", x + y);
	printf("A - B is %f\n", x - y);
	printf("A x B is %f\n", x * y);
	printf("A / B is %f\n", x * 1.0 / y);
	printf("sqrt(A) is %f\n", sqrt(x));
	printf("reciprocal of A is %f\n", 1.0 / x);
	return 0;
}