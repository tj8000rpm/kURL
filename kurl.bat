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
	// �������I�v�V�������ڂ�ݒ肷��
	var options=optionParser(args);

	// �f�o�b�O�\����ON�ݒ肪����ꍇ
	if(options.debug==true)	DEBUG=true;

	// �I�v�V�����̃p�[�X���ʂ���G���[���擾
	var resultCode=options.error;

	//�G���[�R�[�h����
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
	// �ُ�n(�G���[�R�[�h����)�ł������ꍇ�̓G���[�R�[�h��Ԃ��ď������I��
	if(resultCode<0) return resultCode;

	//�G���[�R�[�h�ɖ��Ȃ��ꍇ��HTTP Request�𑗐M����
	//return httpSendOld(options);
	return httpSend(options);
}

/*
 * WinHttp.WinHttpRequest.5.1��p����HTTP���N�G�X�g�𐶐�����
 */
function httpSend(options){
	if(options.debug==true)	DEBUG=true;

	// �f�o�b�O�F�I�v�V�����̐ݒ�l�擾
	if(DEBUG) for(var key in options)WScript.Echo("	"+key+":"+options[key]);

	try {
		var content=null;
		var sendingURL=options.url;
		
		// data�̗L����URL��ύX����
		if(options.data!=null){
			if(options.method == "GET" ){
				sendingURL+="?";
				sendingURL+=options.data;
			}else{
				content=options.data;
			}
			if(DEBUG) WScript.Echo(content);
		}

	    // WinHttpRequest�g�p
	    var http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
	    // �����ݒ�
	    http.open(options.method, sendingURL, false);
		// RedirectFalse
		http.option(6)=options.redirect;

	   	// �ǉ��w�b�_�̐ݒ�
		if(options.header!=null){
			if(DEBUG)	WScript.Echo(options.header);
			for(var key in options.header){
				var val=options.header[key];
	    		http.setRequestHeader(key,val);
			}
		}

		// Content-Type�w�b�_�ݒ�
		if(options.contentType!=null){
	    	http.setRequestHeader("Content-Type", options.contentType);
		}

	    // �v��
		http.send(content);

	    // �������ʕ\��
	    if(DEBUG || options.viewHeader) WScript.Echo("*Status Code : "+http.status + " " + http.statusText);
	    if(DEBUG || options.viewHeader) WScript.Echo(http.getAllResponseHeaders());
	    if(DEBUG || options.viewBody) WScript.Echo(http.responseText);
	} catch (e) {
	    // �G���[�̏ꍇ
	    if(DEBUG)	WScript.Echo("Error(" + (e.number & 0xFFFF) + "):" + e.message);
		return -1;
	}
	return 0;
}

/*
 * ServerXMLHTTP��p����HTTP���N�G�X�g�𐶐�����
 * ���m�̖��_�F
 * �@�T�[�o���烊�_�C���N�g���X�|���X���������ꍇ���_�C���N�g�����{���Ă��܂�
 * �@WinHttp.WinHttpRequest.5.1�ւ̕ύX��\��
 */
function httpSendOld(options){
	if(options.debug==true)	DEBUG=true;

	// �f�o�b�O�F�I�v�V�����̐ݒ�l�擾
	if(DEBUG) for(var key in options)WScript.Echo("	"+key+":"+options[key]);

	try {
		var content=null;
		var sendingURL=options.url;
		
		// data�̗L����URL��ύX����
		if(options.data!=null){
			if(options.method == "GET" ){
				sendingURL+="?";
				sendingURL+=options.data;
			}else{
				content=options.data;
			}
			if(DEBUG) WScript.Echo(content);
		}

	    // ServerXMLHTTP�g�p
	    var http = new ActiveXObject("Msxml2.ServerXMLHTTP");
	    // �����ݒ�
	    http.open(options.method, sendingURL, false);

	   	// �ǉ��w�b�_�̐ݒ�
		if(options.header!=null){
			if(DEBUG)	WScript.Echo(options.header);
			for(var key in options.header){
				var val=options.header[key];
	    		http.setRequestHeader(key,val);
			}
		}

		// Content-Type�w�b�_�ݒ�
		if(options.contentType!=null){
	    	http.setRequestHeader("Content-Type", options.contentType);
		}

	    // �v��
		http.send(content);

	    // �������ʕ\��
	    if(DEBUG || options.viewHeader) WScript.Echo("*Status Code : "+http.status + " " + http.statusText);
	    if(DEBUG || options.viewHeader) WScript.Echo(http.getAllResponseHeaders());
	    if(DEBUG || options.viewBody) WScript.Echo(http.responseText);
	} catch (e) {
	    // �G���[�̏ꍇ
	    if(DEBUG)	WScript.Echo("Error(" + (e.number & 0xFFFF) + "):" + e.message);
		return -1;
	}
	return 0;
}

/**
 * �I�v�V�����p�����[�^�̃p�[�V���O
 * ����:�Ƃ��ăp�����[�^�̔z��
 * �o��:�ݒ肳�ꂽ�I�v�V������object
 * ex) .method="POST"
 *     .header={"Contact":"hoge", "Origin":"foo"}
 *     .contentType=""
 *
 * �G���[�̏ꍇ�̓G���[�R�[�h��擪�ɕt�^�����z������^�[��
 *
 * �����̗���Ƃ��Ă͏ȗ��`�I�v�V������W�J
 * �I�v�V��������������
 * �e�������ŕs���ȃI�v�V�����t�^���@������΃G���[
 */
function optionParser(rawArgs){
	// ��̃I�u�W�F�N�g�̐���
	var options={};
	if(rawArgs.length < 1) {
		options.error=ERROR_INVALID_ARGUMENTS;
		return options;
	}
	
	//rawArg->Array�ɕϊ�����
	var args = new Array();
	for(var i=0;i<rawArgs.length;i++){
		args.push(rawArgs(i));
	}
	if(DEBUG)	WScript.Echo(args);

	// args��擪������o��������������
	// �ȗ��`�̏ꍇ�̏����F
	// �@�ȗ��`(-�n�܂�)�̏ꍇ�͎��̎菇�ŏȗ��`���琳�K�`(--�n�܂�)�ɕϊ�����
	// �@�P�D�ȗ��`�������A�Ȃ��Ă���ꍇ�i-abc�j
	// �@�@�@a��b��c�̏ȗ��`���������Ă���Ɖ��肷��
	// �@�Q�D���̂Ƃ��Aa b c�̂����A�p�����[�^��^����K�v��������̂�����ꍇ��
	// �@�@�@���̗v�f�����o���A����abc�̂���1�ȏ�p�����[�^���K�v�ȃI�v�V����������ꍇ��
	// �@�@�@�񐳋K�Ȏ菇�Ƃ��ăG���[��Ԃ��A�I������B
	// �@�R�D�G���[�ł͂Ȃ��ꍇ��a��b��c�����ꂼ�ꐳ�K�n�ɕϊ����A
	// �@�@�@�p�����[�^c b a�̏����Ő擪�ɒǉ�����
	// ���K�n�̏ꍇ�̏����F
	// �@���K�n�Ŏ��ۂ̏������s���B
	// �@�I�v�V�����ɂ͓�̃^�C�v�݂̂���B
	// �@�P�D�I�v�V���������ŏ������s���p�^�[���iON/OFF�X�C�b�`�j
	// �@�@�@���̏ꍇ�͖߂�l�p�̃I�u�W�F�N�g(options)�ɒ��ڏ�������
	// �@�@�@�Y�I�v�V�����̏������s���B
	// �@�Q�D�I�v�V�����ɑ����p�����[�^���g�p����p�^�[��
	// �@�@�@���̏ꍇ�͎��ɑ����p�����[�^�̓ǂݍ��݂����肵�A�擪���炳��Ɏ擾����
	// �@�@�@�擾�����p�����[�^�������Ė߂�l�p�I�u�W�F�N�g�ɏ������������ށB
	// �K�{�p�����[�^�i����URL�̏����j�F
	// �@��L�����n�ɊY�����Ȃ����͕̂K�{�p�����[�^��URL�ł���Ɖ��肷��
	// �@����URL�̃`�F�b�N�Ȃǂ͍s��Ȃ��B
	// �@URL�͖߂�l�p�̃I�u�W�F�N�g�ɑ΂��ď������݂��s���B
	// �@�������̕K�{�p�����[�^�Ƀq�b�g����ꍇ�̓G���[��ԓ�����
	// �@
	while(args.length>0){
		if(DEBUG)	WScript.Echo("Array:["+args+"]");
		var point=args.shift();

		// Option�̓ǂݍ��ݏ���
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
		// �ȗ��`�̓W�J����
		else if(/^-/.test(point)){
			var subOp=point.replace(/^-/,"").split("");
			var shortAndHasNext=false;
			for(var idx=subOp.length-1;idx>=0;idx--){
				switch(subOp[idx]){
					case "H":
						//�ȗ��`�͖����ɒǉ�
						args.unshift("--header");
						// �I�v�V�����̈��������邽�߃`�F�b�N
						if(!shortAndHasNext) shortAndHasNext=true;
						else{
							options.error=ERROR_INVALID_ARGUMENTS;
							return options;
						}
						break;
					case "X":
						//�ȗ��`�͖����ɒǉ�
						args.unshift("--request");
						// �I�v�V�����̈��������邽�߃`�F�b�N
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
						// �I�v�V�����̈��������邽�߃`�F�b�N
						if(!shortAndHasNext) shortAndHasNext=true;
						else{
							options.error=ERROR_INVALID_ARGUMENTS;
							return options;
						}
						break;
					case "F":
						args.unshift("--form");
						// �I�v�V�����̈��������邽�߃`�F�b�N
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
			//���̂Ƃ���URL�܂������Ȃ��O��
			if(options.url!=null){
				options.error=ERROR_MULTIPLE_URLS;
				return options;
			}
			options.url=point;
		}
	}

	// �G���[�����FURL���ݒ肳��Ă��Ȃ��ŏI������ꍇ�̓G���[���������{
	if(options.url==null)		options.error=ERROR_NO_URLS;

	// �f�t�H���g����
	// �I�v�V�����Őݒ肪�Ȃ��������ڂł������ɕK�{�ȍ��ڂ�ݒ�
	if(options.viewHeader==null)		options.viewHeader=false;
	if(options.viewBody==null)		options.viewBody=true;
	if(options.error==null)		options.error=NOERROR;
	if(options.method==null)	options.method="GET";
	if(options.redirect==null)	options.redirect=false;
	return options;
}

/*
 * Help��\�����邽�߂̊֐�
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
 * URL�G���R�[�h�����{
 * key��val��URL�G���R�[�h����
 * key=val�̌`�Ń��^�[��
 */
function escapeParams(key,val) {
    var param = "";
    // �p�����[�^�ݒ�
    param += encodeURIComponent(key).split("%20").join("+")
        + "=" + encodeURIComponent(val).split("%20").join("+");
    return param;
}
