/*
 rule.summary=Check if the response is a raw PDF or a Binary resource
 rule.description=Check if the response has either a Content-Type of "application/pdf" or a body containing a Binary resource
*/

if (response.header("Content-Type").contains("application/pdf")) {
	assert true;
} else {
	assert response.getFhirPathBoolean("Binary.exists()");
}
