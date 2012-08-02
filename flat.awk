#!/usr/bin/awk -f
function conv_unicode_to_utf8(u) { return "<\\u" u ">"; }
function json_str(str,	i,l,c,r) {
	l = length(str)
	if (! ( (substr(str, 1, 1) == "\"") && (substr(str, l, 1) == "\"") ) )
		return str
	str = substr(str, 2, length(str)-2)
	for (i = 1; i <= l; i++) {
		c = substr(str, i, 1)
		if (c == "\\") {
			c = substr(str, ++i, 1)
			     if (c == "b") r = r "\010"
			else if (c == "f") r = r "\014"
			else if (c == "n") r = r "\012"
			else if (c == "r") r = r "\015"
			else if (c == "t") r = r "\011"
			else if (c == "u") { r = r conv_unicode_to_utf8(toupper(substr(str, i+1, 4))); i+=4; }
			else               r = r c
		} else { r = r c }
	}
	return r
}

function json_add_element(arr, val, level, ordered, key,
	i, k)
{
	k = ""
	for (i = 1; i <= level; i++)
		k = k (ordered[i] ? ordered[i] : key[i]) (i < level ? "," : "")
	arr[k] = val
}

function json_to_array(str, arr,
	i, a, n, backslash, quote, code, val, key, level, ordered, len)
{
#	print str > "/dev/stderr"
	for (i in arr)
		delete arr[i]
	level = 0;
	len = length(str)

	for (i = 1; i <= len; ++i)
	{
		#skip ws
		while ( (c=substr(str,i,1)) && !quote && ( (c == " ") || (c == "\t") || (c == "\n") ) && (i < len))
			i++
		if (quote && (c == "\\")) {
			c = substr(str, ++i, 1)
			val = val "\\" c
		} else if (c == "\"") {
			val = val c
			quote = !quote
		} else if (quote) {
			val = val c
		} else if (c == ":") {
			key[level] = json_str(val)
			val = ""
		} else if (c == "[") {
			level++
			ordered[level] = 1
		} else if (c == "{") {
			level++
		} else if (c == "]" || (c == "}")) {
			if (p != "]" && p != "}") {
				json_add_element(arr, val, level, ordered, key, p, c)
				val = ""
			}
			delete ordered[level]
			level--
		}
		else if (c == ",") {
			if (p != "]" && p != "}") {
				json_add_element(arr, val, level, ordered, key, p, c)
				val = ""
			}
			if (ordered[level]) ordered[level]++
		} else {
			val = val c
		}
		p = c #previous (uh, need better states)
	}
}

BEGIN { RS="" }
{
	json_to_array($0,json)
	for (i in json) {
		printf("[%s]=[%s]\n",i,json_str(json[i]))
	}
}
