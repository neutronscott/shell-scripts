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

function json_to_array(str, arr, key_chain, key_type,
	key, i, quote, val, len)
{
	#first entry
	if (!length(key_chain)) {
#		print str > "/dev/stderr"
		for (i in arr)
			delete arr[i]
		key_chain = "root"
	}
	len = length(str)

	for (i = 1; i <= len; ++i)
	{
		#skip ws
		while ( (c=substr(str,i,1)) && !quote && ( (c == " ") || (c == "\t") || (c == "\n") ) && (i < len))
			i++

		if (quote && (c == "\\")) {
			#do not decode now. just make sure we don't set quote=0 for \"
			c = substr(str, ++i, 1)
			val = val "\\" c
		} else if (c == "\"") {
			val = val c
			quote = !quote
		} else if (quote) {
			val = val c
		} else if (c == ":") {
			key = json_str(val)
			val = ""
		} else if (c == "[" || c == "{") {
			if (key_type=="arr") key++
			i+=json_to_array(substr(str, i+1), arr, key_chain key ",", c=="["?"arr":"obj")
		} else if (c == "]" || (c == "}") || (c == ",")) {
			if (length(val) > 0) {
				if (key_type=="arr") key++
				arr[key_chain key]=val
				val=""
			}
			if (c != ",")
				break
		} else {
			val = val c
		}
	}
	return i
}

BEGIN { RS="" }
{
	json_to_array($0,json)
	for (i in json) {
		printf("[%s]=[%s]\n",i,json_str(json[i]))
	}
}
