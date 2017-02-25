#!/usr/bin/python
#coding: utf-8

# 作者 - suyanchun,liyuchu - 573997484@qq.com
# 分析访问日志access_log中
# 域名host状态码http_code的top N
# 访问链接：https://github.com/sycflash/mygit/blob/master/analog.py
# 默认日志路径:
# /usr/local/ngx_openresty_xycdn/nginx/logs/access.standard.xcdn.log
# /usr/local/sandai/xserver/nginx/logs/access.log
# 使用方法：python analog.py www.test.com 404 5

import sys,os,json,re,urllib,requests,hashlib
reload(sys)
sys.setdefaultencoding("UTF-8")

# global options
G_HOST = ""
G_SOURCES = []
G_SOURCES_HOST = ""


# function area

def sign(domain):
	m = hashlib.md5()  
	m.update('{"domain":["%s"]}&key=h653x#8f%%^yuWerS'%(domain))
	return m.hexdigest()

def show_usage():
	print "Usage:%s host http_code [top_N=5]" % (__file__)
	return 0

def check_host(host):
	pass
	return True

def check_http_code(http_code):
	p = re.compile(r"^[1-5][0-9]{2}$")
	if not p.match(http_code.strip()):
		print "HTTP Code [%s] Error" % (http_code)
		return False
	return True

def check_log_file(log_files):
	for log_file in log_files:
		if os.path.exists(log_file):
			return log_file
  	return False

def get_host_info(host):
	host_xcdn_info = {}
#        url = 'http://master.xrsm.xcdn:90/get_cache'
	url = 'http://master.proxy.xcdn.gslb.p2cdn.com:8066/dmm/domain_info_get?sign=%s' % (sign(host))
        ret_info = requests.post(url,data='{"domain":["%s"]}'%host ,headers={'Host':'domainmgr.sj.xunlei.com'} ).json()
        for info in ret_info.get('data'):
		if host.strip() == info.get('domain'):
			host_xcdn_info = {'domain':info.get('domain'),
					  'sources':info.get('sources'),
					  'xcdn_group_id':info.get('xcdn_group_id'),	
					  'add_req_hdrs':info.get('add_req_hdrs')
 						}
			break
	return host_xcdn_info
def show_host_info(host_xcdn_info):
	print "--[ 域名信息 ]----------------------"
	print "域名:\t\t" + host_xcdn_info['domain']
	print "源站地址:\t" + '|'.join([x for x in host_xcdn_info['sources']])
	print "xcdn分组:\t" + host_xcdn_info['xcdn_group_id']
	print "------------------------------------"

def check_url_status(sources,headers,uri):
    url = "http://{domain}{uri}".format(domain=sources[0],uri=uri)
#    print url,headersG
    try:
      status = requests.get(url,headers=headers).status_code
      if str(status) == sys.argv[2]:
        return "{0}[match]".format(status)
      else:
        return "{0}[notMatch]".format(status)
    except Exception, e:
      return "0[err]"

def static_host_code(log_file,sources,add_req_hdrs,host,code,top_N=5):
	if not check_http_code(code) or not check_log_file(log_file):
		sys.exit(2)


	top_N = int(top_N)
	static_dict = {}
	seperator = "\001"
	with open(log_file) as f:
		for line in f:
			line_arr = line.split(seperator)
			if line_arr[7] == code and host == line_arr[3]:
				if static_dict.has_key(line_arr[6]):
					static_dict[line_arr[6]] += 1
				else:
					static_dict[line_arr[6]] = 1
	
	print "-[TOP %s]http_code:%s---------------" % (top_N,code) 
	dict = sorted(static_dict.iteritems(), key = lambda d:d[1], reverse = True)
	
	bad_code_uri = []
	print "方法 Uri         协议 次数 源站状态码 "
	for i in dict:
		uri = i[0].split()
		print uri[0],uri[1],uri[2],i[1],check_url_status(sources,add_req_hdrs,uri[1])
		top_N -= 1
		bad_code_uri.append(uri)
		if top_N == 0:
			break
	print "------------------------------------"

# main function
def main_run():
	if len(sys.argv) < 3:
		show_usage()
		sys.exit(1)
	else:
		log_files = [
			'/usr/local/ngx_openresty_xycdn/nginx/logs/access.standard.xcdn.log',
                        '/usr/local/sandai/xserver/nginx/logs/access.log' ]
		log_file = check_log_file(log_files)
		if not log_file :
			print 'Log file does not exist'
                   	sys.exit(1)
                print "-[日志文件]--------------------------"
                print log_file
		host_xcdn_info = get_host_info(sys.argv[1])
		show_host_info(host_xcdn_info)
		static_host_code(log_file,host_xcdn_info.get('sources'),host_xcdn_info.get('add_req_hdrs'),*sys.argv[1:])

# script run enter
main_run()
