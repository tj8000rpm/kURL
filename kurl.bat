@if (1==1) /*
@ECHO OFF

:JSCRIPT
CScript //Nologo //E:JScript "%~f0" %*

GOTO :EOF
rem */
@end

var VERSION = 0.1;
var LASTUPDATE = "2017/01/04";

var NOERROR = 0;
var ERROR_NO_URLS	= -5;
var ERROR_MULTIPLE_URLS	= -4;
var ERROR_INVALID_ARGUMENTS = -3;
var ERROR_UNKNOWN_ARGUMENTS = -2;
var ERROR_GENERAL = -1;
var DEBUG = false;

WScript.quit(main(WScript.arguments));

// Main function
function main(args){
	// 引数よりオプション項目を設定する
	var options=optionParser(args);

	// デバッグ表示のON設定がある場合
	if(options.debug==true)	DEBUG=true;

	// オプションのパース結果からエラーを取得
	var resultCode=options.error;

	//エラーコードから
	switch(resultCode){
		case ERROR_GENERAL:
			WScript.Echo("GENERAL ERROR");
			break;
		case ERROR_UNKNOWN_ARGUMENTS:
			WScript.Echo("UNKNOWN ARGUMNET(S)");
			break;
		case ERROR_INVALID_ARGUMENTS:
			WScript.Echo("INVALID ARGUMENT(S)");
			break;
		case ERROR_NO_URLS:
			WScript.Echo("NO URL");
			break;
		case ERROR_MULTIPLE_URLS:
			WScript.Echo("MULTIPLE URL");
			break;
	}
	// 異常系(エラーコードが負)であった場合はエラーコードを返して処理を終了
	if(resultCode<0) return resultCode;

	//エラーコードに問題ない場合はHTTP Requestを送信する
	//return httpSendOld(options);
	return httpSend(options);
}

/*
 * WinHttp.WinHttpRequest.5.1を用いてHTTPリクエストを生成する
 */
function httpSend(options){
	if(options.debug==true)	DEBUG=true;

	// デバッグ：オプションの設定値取得
	if(DEBUG) for(var key in options)WScript.Echo("	"+key+":"+options[key]);

	try {
		var content=null;
		var sendingURL=options.url;
		
		// dataの有無でURLを変更する
		if(options.data!=null){
			if(options.method == "GET" ){
				sendingURL+="?";
				sendingURL+=options.data;
			}else{
				content=options.data;
			}
			if(DEBUG) WScript.Echo(content);
		}

	    // WinHttpRequest使用
	    var http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
	    // 初期設定
	    http.open(options.method, sendingURL, false);
		// RedirectFalse
		http.option(6)=options.redirect;

	   	// 追加ヘッダの設定
		if(options.header!=null){
			if(DEBUG)	WScript.Echo(options.header);
			for(var key in options.header){
				var val=options.header[key];
	    		http.setRequestHeader(key,val);
			}
		}

		// Content-Typeヘッダ設定
		if(options.contentType!=null){
	    	http.setRequestHeader("Content-Type", options.contentType);
		}

	    // 要求
		http.send(content);

	    // 応答結果表示
	    if(DEBUG || options.viewHeader) WScript.Echo("*Status Code : "+http.status + " " + http.statusText);
	    if(DEBUG || options.viewHeader) WScript.Echo(http.getAllResponseHeaders());
	    if(DEBUG || options.viewBody) WScript.Echo(http.responseText);
	} catch (e) {
	    // エラーの場合
	    if(DEBUG)	WScript.Echo("Error(" + (e.number & 0xFFFF) + "):" + e.message);
		return -1;
	}
	return 0;
}

/*
 * ServerXMLHTTPを用いてHTTPリクエストを生成する
 * 既知の問題点：
 * 　サーバからリダイレクトレスポンスがあった場合リダイレクトを実施してしまう
 * 　WinHttp.WinHttpRequest.5.1への変更を予定
 */
function httpSendOld(options){
	if(options.debug==true)	DEBUG=true;

	// デバッグ：オプションの設定値取得
	if(DEBUG) for(var key in options)WScript.Echo("	"+key+":"+options[key]);

	try {
		var content=null;
		var sendingURL=options.url;
		
		// dataの有無でURLを変更する
		if(options.data!=null){
			if(options.method == "GET" ){
				sendingURL+="?";
				sendingURL+=options.data;
			}else{
				content=options.data;
			}
			if(DEBUG) WScript.Echo(content);
		}

	    // ServerXMLHTTP使用
	    var http = new ActiveXObject("Msxml2.ServerXMLHTTP");
	    // 初期設定
	    http.open(options.method, sendingURL, false);

	   	// 追加ヘッダの設定
		if(options.header!=null){
			if(DEBUG)	WScript.Echo(options.header);
			for(var key in options.header){
				var val=options.header[key];
	    		http.setRequestHeader(key,val);
			}
		}

		// Content-Typeヘッダ設定
		if(options.contentType!=null){
	    	http.setRequestHeader("Content-Type", options.contentType);
		}

	    // 要求
		http.send(content);

	    // 応答結果表示
	    if(DEBUG || options.viewHeader) WScript.Echo("*Status Code : "+http.status + " " + http.statusText);
	    if(DEBUG || options.viewHeader) WScript.Echo(http.getAllResponseHeaders());
	    if(DEBUG || options.viewBody) WScript.Echo(http.responseText);
	} catch (e) {
	    // エラーの場合
	    if(DEBUG)	WScript.Echo("Error(" + (e.number & 0xFFFF) + "):" + e.message);
		return -1;
	}
	return 0;
}

/**
 * オプションパラメータのパーシング
 * 入力:としてパラメータの配列
 * 出力:設定されたオプションのobject
 * ex) .method="POST"
 *     .header={"Contact":"hoge", "Origin":"foo"}
 *     .contentType=""
 *
 * エラーの場合はエラーコードを先頭に付与した配列をリターン
 *
 * 処理の流れとしては省略形オプションを展開
 * オプションを順次処理
 * 各処理中で不正なオプション付与方法があればエラー
 */
function optionParser(rawArgs){
	// 空のオブジェクトの生成
	var options={};
	if(rawArgs.length < 1) {
		options.error=ERROR_INVALID_ARGUMENTS;
		return options;
	}
	
	//rawArg->Arrayに変換する
	var args = new Array();
	for(var i=0;i<rawArgs.length;i++){
		args.push(rawArgs(i));
	}
	if(DEBUG)	WScript.Echo(args);

	// argsを先頭から取り出し順次処理する
	// 省略形の場合の処理：
	// 　省略形(-始まり)の場合は次の手順で省略形から正規形(--始まり)に変換する
	// 　１．省略形が複数連なっている場合（-abc）
	// 　　　aとbとcの省略形がくっついていると仮定する
	// 　２．このとき、a b cのうち、パラメータを与える必要があるものがある場合は
	// 　　　次の要素も取り出す、仮にabcのうち1つ以上パラメータが必要なオプションがある場合は
	// 　　　非正規な手順としてエラーを返し、終了する。
	// 　３．エラーではない場合はaとbとcをそれぞれ正規系に変換し、
	// 　　　パラメータc b aの順序で先頭に追加する
	// 正規系の場合の処理：
	// 　正規系で実際の処理を行う。
	// 　オプションには二つのタイプのみある。
	// 　１．オプションだけで処理を行うパターン（ON/OFFスイッチ）
	// 　　　この場合は戻り値用のオブジェクト(options)に直接書き込み
	// 　　　該オプションの処理を行う。
	// 　２．オプションに続くパラメータを使用するパターン
	// 　　　この場合は次に続くパラメータの読み込みを仮定し、先頭からさらに取得する
	// 　　　取得したパラメータをもって戻り値用オブジェクトに処理を書き込む。
	// 必須パラメータ（宛先URLの処理）：
	// 　上記処理系に該当しないものは必須パラメータのURLであると仮定する
	// 　特にURLのチェックなどは行わない。
	// 　URLは戻り値用のオブジェクトに対して書き込みを行う。
	// 　複数この必須パラメータにヒットする場合はエラーを返答する
	// 　
	while(args.length>0){
		if(DEBUG)	WScript.Echo("Array:["+args+"]");
		var point=args.shift();

		// Optionの読み込み処理
		if(/^--/.test(point)){
			var subOp=point.replace(/^--/,"");
			switch(subOp){
				case "header":
					if(!args.length>0){
						options.error=ERROR_INVALID_ARGUMENTS;
						return options;
					}
					var line=args.shift();

					if(!/^[^:]+:.+$/.test(line)){
						options.error=ERROR_INVALID_ARGUMENTS;
						return options;
					}

					var val = line.replace(/^[^:]+:/,"");
					var key = line.replace(/:.*$/,"");

					if(options.header==null)
						options.header={};

					options.header[key]=val;

					break;
				case "verbose":
					options.debug=true;
					break;
				case "location":
					options.redirect=true;
					break;
				case "include":
					options.viewHeader=true;
					options.viewBody=true;
					break;
				case "head":
					options.method="HEAD";
					options.viewHeader=truh;
					options.viewBody=true;
					break;
				case "data-ascii":
				case "data":
					if(options.method==null) options.method="POST";

					if(!args.length>0){
						options.error=ERROR_INVALID_ARGUMENTS;
						return options;
					}
					var val=args.shift();

					if(options.data==null)	options.data=val;
					else					options.data+="&"+val;
					if(options.contentType==null)
						options.contentType="application/x-www-form-urlencoded";
					break;
				case "data-urlencode":
					if(options.method==null) options.method="POST";

					if(!args.length>0){
						options.error=ERROR_INVALID_ARGUMENTS;
						return options;
					}
					var val=args.shift();

					var content=val.replace(/^[^=]+=/,"");
					var keyArray=val.match(/(^[^=]+)=/);
					if(keyArray==null){
						options.error=ERROR_INVALID_ARGUMENTS;
						return options;
					}
					var data=escapeParams(keyArray[1],content);

					if(options.data==null)	options.data=data;
					else					options.data+="&"+data;
					if(options.contentType==null)
						options.contentType="application/x-www-form-urlencoded";

					break;
				case "form":
					if(options.method==null) options.method="POST";
					break;
				case "get": options.method="GET"; break;
				case "request":
					if(!args.length>0){
						options.error=ERROR_INVALID_ARGUMENTS;
						return options;
					}
					var val=args.shift();
					options.method=val;
					break;
				default:
					options.error=ERROR_UNKNOWN_ARGUMENTS;
					return options;
			}
		}
		// 省略形の展開処理
		else if(/^-/.test(point)){
			var subOp=point.replace(/^-/,"").split("");
			var shortAndHasNext=false;
			for(var idx=subOp.length-1;idx>=0;idx--){
				switch(subOp[idx]){
					case "H":
						//省略形は末尾に追加
						args.unshift("--header");
						// オプションの引数があるためチェック
						if(!shortAndHasNext) shortAndHasNext=true;
						else{
							options.error=ERROR_INVALID_ARGUMENTS;
							return options;
						}
						break;
					case "X":
						//省略形は末尾に追加
						args.unshift("--request");
						// オプションの引数があるためチェック
						if(!shortAndHasNext) shortAndHasNext=true;
						else{
							options.error=ERROR_INVALID_ARGUMENTS;
							return options;
						}
						break;
					case "v": args.unshift("--verbose");	break;
					case "i": args.unshift("--include");	break;
					case "L": args.unshift("--location");	break;
					case "I": args.unshift("--head");		break;
					case "G": args.unshift("--get");		break;
					case "d":
						args.unshift("--data"); //--data "datas"
						// オプションの引数があるためチェック
						if(!shortAndHasNext) shortAndHasNext=true;
						else{
							options.error=ERROR_INVALID_ARGUMENTS;
							return options;
						}
						break;
					case "F":
						args.unshift("--form");
						// オプションの引数があるためチェック
						if(!shortAndHasNext) shortAndHasNext=true;
						else{
							options.error=ERROR_INVALID_ARGUMENTS;
							return options;
						}
						break;
					default:
						options.error=ERROR_UNKNOWN_ARGUMENTS;
						return options;
				}
			}
			if(subOp.length!=1) shortAndHasNext=false;
			//if(shortAndHasNext) args.push(args.shift());

		} else{
			//このときはURLまちしかない前提
			if(options.url!=null){
				options.error=ERROR_MULTIPLE_URLS;
				return options;
			}
			options.url=point;
		}
	}

	// エラー処理：URLが設定されていないで終了する場合はエラー処理を実施
	if(options.url==null)		options.error=ERROR_NO_URLS;

	// デフォルト処理
	// オプションで設定がなかった項目でかつ処理に必須な項目を設定
	if(options.viewHeader==null)		options.viewHeader=false;
	if(options.viewBody==null)		options.viewBody=true;
	if(options.error==null)		options.error=NOERROR;
	if(options.method==null)	options.method="GET";
	if(options.redirect==null)	options.redirect=false;
	return options;
}

/*
 * Helpを表示するための関数
 */
function showHelp(){
	WScript.Echo("kURL "+VERSION+" "+LASTUPDATE);
	WScript.Echo("kURL is WSH JScript software for Windows like cURL." );
	WScript.Echo("");
	WScript.Echo("Usage: kurl [options...] <url>" );
	WScript.Echo(" -i, --include              Output headers and body" );
	WScript.Echo(" -I, --head                 Output headers (using HEAD method)" );
	WScript.Echo(" -H, --header LINE          Added custom header(s)" );
	WScript.Echo(" -X, --request METHOD       Change HTTP method(Prior to other options)" );
	WScript.Echo(" -G, --get                  Using GET method [--data] sending)" );
	WScript.Echo(" -d, --data DATA            Posting data" );
	WScript.Echo("     --data-ascii DATA      Same --data" );
	WScript.Echo("     --data-urlencode DATA  Posting data with urlencoded" );
}

/*
 * URLエンコードを実施
 * keyとvalをURLエンコードして
 * key=valの形でリターン
 */
function escapeParams(key,val) {
    var param = "";
    // パラメータ設定
    param += encodeURIComponent(key).split("%20").join("+")
        + "=" + encodeURIComponent(val).split("%20").join("+");
    return param;
}
