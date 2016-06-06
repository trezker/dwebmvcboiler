$(function() {
	$.getScript("/source/js/test/user_test.js").fail(function( jqxhr, settings, exception ) {
    	console.log( "Triggered ajaxError handler." );
    	console.log( exception );
	});
});

function test_assert(cond) {
	if(!cond) {
		try {
			throw new Error();
		}
		catch(e) {
			var stackLine = e.stack.split('\n')[1];
			var testname = stackLine.substring(0, stackLine.indexOf("/"));
			var position = stackLine.substring(stackLine.indexOf(" "));
			$("body").append("<p>ERROR: " + testname + position + "</p>");
		}
	}
}

function run_test_suite(suite) {
	for (var test in suite) {
		console.log(suite[test]);
		suite[test]();
	}
}