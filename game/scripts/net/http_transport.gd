class_name HttpTransport
extends NetTransport
# NetTransport over HTTP to the Cloudflare Worker (LLD-network-match.md 3.2). Each call
# adds a one-shot HTTPRequest under `host`, which must be in the scene tree. The server
# URL is the project setting mythcards/net/server_url, or --server=<url> on the command
# line (for `wrangler dev`).

const URL_SETTING := "mythcards/net/server_url"
const TIMEOUT_SECONDS := 15.0

var host: Node
var base_url: String


func _init(host_node: Node, url: String = "") -> void:
	host = host_node
	base_url = (url if url != "" else server_url()).trim_suffix("/")


static func server_url() -> String:
	for arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if arg.begins_with("--server="):
			return arg.trim_prefix("--server=")
	# The browser tests point the test web build at `wrangler dev` with ?server=<url>. Only
	# that build reads it, so an invite link can't send players to another server.
	if OS.has_feature("web") and OS.has_feature(TestBridge.FEATURE_TAG):
		var url := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('server') || ''", true))
		if url != "":
			return url
	return str(ProjectSettings.get_setting(URL_SETTING, ""))


func create_room(team_id: String, version: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/rooms", "", {"team_id": team_id, "version": version})


func join_room(code: String, version: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/rooms/%s/join" % code.uri_encode(), "", {"version": version})


func fetch_log(code: String, token: String, since: int) -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/rooms/%s/log?since=%d" % [code.uri_encode(), since], token, null)


func append(code: String, token: String, entry: Dictionary) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/rooms/%s/log" % code.uri_encode(), token, entry)


func _request(method: int, path: String, token: String, body: Variant) -> Dictionary:
	if base_url == "" or host == null or not host.is_inside_tree():
		return NetTransport.result(0, {}, "no server")
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_SECONDS
	host.add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if token != "":
		headers.append("Authorization: Bearer %s" % token)
	var data := JSON.stringify(body) if body != null else ""
	var err := http.request(base_url + path, headers, method, data)
	if err != OK:
		http.queue_free()
		return NetTransport.result(0, {}, "request failed (%d)" % err)
	var response: Array = await http.request_completed   # [result, code, headers, body]
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS:
		return NetTransport.result(0, {}, "can't reach the server")
	var parsed = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	return NetTransport.result(int(response[1]), parsed if parsed is Dictionary else {})
