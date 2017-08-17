module boiler.HttpResponse;

class HttpResponse {
	int code;
	string content;

	void writeBody(string content, int code){
		this.content = content;
		this.code = code;
	}
}