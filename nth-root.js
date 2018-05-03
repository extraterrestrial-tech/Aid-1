
var fixedOne = 1000000000000000000;

function power(_a, _n) {
	var t = _a;
	for(var i=1; i<_n; i++) {
		t = Math.floor(t * _a / fixedOne);
	}
	return t;
}

function nthRoot(_a, _n) {

	var x = Math.floor((fixedOne + _a) / 2);

    while(true) {
    	var t = power(x, _n);
    	console.log('x = ' + x + '       t = ' + t);
    	if(t == _a) {
    		return x;
    	}
    	x = x - Math.floor(fixedOne * (power(x, _n) - _a) / (_n * power(x, _n - 1)));
    }
}

function test(a, n) {
	console.log('***');
	console.log(a + ' ^ ' + n + ' = ' + power(a, n));
	var b = power(a, n);
	console.log('root ' + n + ' of ' + b + ' = ' + nthRoot(b, n));
}

test(2 * fixedOne, 2);
test(2 * fixedOne, 3);
test(2 * fixedOne, 4);

test(10 * fixedOne, 2);
test(100 * fixedOne, 2);
test(10000 * fixedOne, 2);

test(3.14159265358979323 * fixedOne, 5);