---
layout: post
title:  "My Website"
date:   2024-04-12 00:45:00 -0400
categories: website
---
After 10+ years of wishing I had a home on the internet, I recently made [my website][cf-website]. Here's how.

## How I got the server/website
- Vultr OpenBSD VPS
- Epik to get the domain and handle DNS

## About the website
- Hosted on OpenBSD using httpd (no 3rd-party tools were installed at all)
- https using relayd and acme
- No frameworks, just plain html and style.css

## Config files
`/etc/acme-client.conf`
{% highlight conf %}
authority letsencrypt {
        api url "https://acme-v02.api.letsencrypt.org/directory"
        account key "/etc/acme/letsencrypt-privkey.pem"
}

authority letsencrypt-staging {
        api url "https://acme-staging.api.letsencrypt.org/directory"
        account key "/etc/acme/letsencrypt-staging-privkey.pem"
}

domain conjfrnk.com {
       alternative names { www.conjfrnk.com }
       domain key "/etc/ssl/private/conjfrnk.com.key"
       domain certificate "/etc/ssl/conjfrnk.com.crt"
       domain full chain certificate "/etc/ssl/conjfrnk.com.fullchain.pem"
       sign with letsencrypt
}
{% endhighlight %}

`/etc/httpd.conf`
{% highlight conf %}
server "conjfrnk.com" {
	listen on 127.0.0.1 port 8080
	root "/htdocs/www.conjfrnk.com"
	location "/.well-known/acme-challenge/*" {
		root "/acme"
		request strip 2
	}
}

server "www.conjfrnk.com" {
	listen on 127.0.0.1 port 8080
	block return 301 "https://conjfrnk.com$REQUEST_URI"
}

server "conjfrnk.com" {
	listen on * port 80
	alias "www.conjfrnk.com"
	block return 301 "https://conjfrnk.com$REQUEST_URI"
} 
{% endhighlight %}

### Redirections
I have configured `/etc/httpd.conf` such that it will redirect `www.conjfrnk.com` to `conjfrnk.com`. I like the simple look better, plus `www` seems way too redundant.

`/etc/relayd.conf`
{% highlight conf %}
include "/etc/ips.conf"

table <local> { 127.0.0.1 }

http protocol https {
	tls ciphers "HIGH:!aNULL:!SSLv3:!DSS:!ECDSA:!RSA:-ECDH:ECDHE:+SHA384:+SHA256"
	tls cipher-server-preference
	tls no client-renegotiation
	tls keypair "conjfrnk.com"

	match request header append "X-Forwarded-For" value "$REMOTE_ADDR"
	match request header append "X-Forwarded-Port" value "$REMOTE_PORT"

	match response header set "Referrer-Policy" value "same-origin"
	match response header set "X-Frame-Options" value "deny"
	match response header set "X-XSS-Protection" value "1; mode=block"
	match response header set "X-Content-Type-Options" value "nosniff"
	match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
	match response header set "Content-Security-Policy" value "default-src 'self' avatars.githubusercontent.com projecteuler.net"
	match response header set "Permissions-Policy" value "accelerometer=()"
	match response header set "Cache-Control" value "max-age=86400"

	return error
	pass
}

relay wwwtls {
	listen on $ipv4 port 443 tls
	protocol https
	forward to <local> port 8080
}

relay www6tls {
	listen on $ipv6 port 443 tls
	protocol https
	forward to <local> port 8080
}
{% endhighlight %}

## Cron
I am using a cronjob to refresh certificates and reboot httpd as necessary. I also use cron to download and apply system/package updates for OpenBSD:

`30 	3 	* 	* 	* 	acme-client conjfrnk.com && rcctl reload httpd`

`30	4	*	*	0	syspatch && pkg_add -u && reboot`

## Sources
I incorporated parts of the [official OpenBSD guide][official-guide] and [this unofficial guide][unofficial-guide], making modifications as necessary. As for the website's content, I would like to credit [Andrej Karpathy][style-inspiration] for having the best-designed personal website I've seen, by a wide margin. I used his `style.css` as a jumping-off point for my own, and I expect my style to develop further in the future.

[cf-website]: https://conjfrnk.com
[official-guide]: https://www.openbsdhandbook.com/services/webserver/ssl
[unofficial-guide]: https://citizen428.net/blog/self-hosting-static-site-openbsd-httpd-relayd
[style-inspiration]: https://karpathy.ai
