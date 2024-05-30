---
layout: post
title:  "My Website"
date:   2024-04-15 13:00:00 -0400
---
After 10+ years of wishing I had a home on the internet, I recently made [my website][cf-website]. Here's how.

## How I got the server/website
- Vultr OpenBSD VPS
- Epik to get the domain and handle DNS

## About the website
- Hosted on OpenBSD using httpd (no 3rd-party tools were installed at all)
- https using relayd and acme
- No frameworks, just plain `index.html` and `style.css`
- It's [pretty fast][website-speed]

### Why OpenBSD?
I agree with many of their design choices. Also, it's an [innovative][openbsd-innovations] and [secure][openbsd-security] complete OS. While it may not be [as fast as Linux or another choice][openbsd-performance], I don't need a crazy amount of performance. I'd rather have something stable and secure. More [here][openbsd-rocks].

### Why no frameworks?
Similar reason. I despise bloat--also I have no idea how to use many frameworks. I have tried, and every one of them is a headache. Sometimes dealing with a headache is worth it if that's what you need. If I needed it, I'd probably get someone else to do the coding for me. Not my cup of tea.

## Accessibility
I used [this resource][contrast-guide] to inform my color formatting decisions

## Source files
I have backed up all of the source files for the website itself to [a self-hosted git repository][git-repo]

### Compression
I have chosen to compress many files using `gzip`, automated by the script `compress.sh`:

{% highlight sh %}
#!/usr/local/bin/bash

gzip -5fk style.css
gzip -7fk *.html
find assets/ -type f -not -name "*.gz" -exec gzip -4fk "{}" \;
{% endhighlight %}

The `/etc/httpd.conf` and `/etc/relayd.conf` files also reflect `gzip`

## Config files
### `/etc/acme-client.conf`
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
       domain full chain certificate "/etc/ssl/conjfrnk.com.crt"
       sign with letsencrypt
}
{% endhighlight %}

### `/etc/httpd.conf`
{% highlight conf %}
server "conjfrnk.com" {
	listen on 127.0.0.1 port 8080
	root "/htdocs/www.conjfrnk.com"
	gzip-static
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

### `/etc/relayd.conf`
{% highlight conf %}
include "/etc/ips.conf"

table <local> { 127.0.0.1 }

http protocol https {
    tls ciphers "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:!aNULL:!SSLv3:!DSS:!ECDSA:!RSA"
    tls cipher-server-preference
    tls no client-renegotiation
    tls no session tickets
    tls keypair "conjfrnk.com"

    match request header append "X-Forwarded-For" value "$REMOTE_ADDR"
    match request header append "X-Forwarded-Port" value "$REMOTE_PORT"

    match response header set "Referrer-Policy" value "strict-origin-when-cross-origin"
    match response header set "X-Frame-Options" value "deny"
    match response header set "X-XSS-Protection" value "1; mode=block"
    match response header set "X-Content-Type-Options" value "nosniff"
    match response header set "Strict-Transport-Security" value "max-age=63072000; includeSubDomains; preload"
    match response header set "Content-Security-Policy" value "default-src 'none'; script-src 'self' 'nonce-analytics'; object-src 'none'; style-src 'self'; img-src 'self' projecteuler.net; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; connect-src 'self' www.googletagmanager.com www.google-analytics.com"
    match response header set "Permissions-Policy" value "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=()"
    match response header set "Cache-Control" value "max-age=31536000, immutable"
    match response header set "Accept-Encoding" value "gzip, deflate, br"

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

`30 3 	* 	* 	* 	acme-client conjfrnk.com && rcctl reload httpd relayd`

`30 4	*	*	0	pkg_add -u && syspatch && reboot`

Certificate/httpd refreshes happen every night at 3:30am and updates happen every Sunday at 4:30am. Manual urgent updates are performed as necessary.

## Sources
I incorporated parts of the [official OpenBSD guide][official-guide] and [this unofficial guide][unofficial-guide], making modifications as necessary. As for the website's content, I would like to credit [Andrej Karpathy][style-inspiration] for having the best-designed personal website I've seen, by a wide margin. I used his `style.css` as a jumping-off point for my own, and I expect my style to develop further in the future. I got all of the SVG icons from [this great website][svg-source].

I also used this [SRI Hash Generator][sri-hash] to secure my Google Tag Manager scripts (Google Analytics used to count visitors)

[cf-website]: https://conjfrnk.com
[official-guide]: https://www.openbsdhandbook.com/services/webserver/ssl
[unofficial-guide]: https://citizen428.net/blog/self-hosting-static-site-openbsd-httpd-relayd
[style-inspiration]: https://karpathy.ai
[svg-source]: https://www.svgrepo.com
[git-repo]: https://git.loftyields.com/connor-website/tree
[openbsd-innovations]: https://www.openbsd.org/innovations.html
[openbsd-security]: https://www.openbsd.org/security.html
[openbsd-performance]: https://news.ycombinator.com/item?id=8535150
[openbsd-rocks]: https://why-openbsd.rocks/fact
[contrast-guide]: https://dequeuniversity.com/rules/axe/4.8/color-contrast
[website-speed]: https://pagespeed.web.dev/analysis/https-conjfrnk-com/q1jkxm2u1d?hl=en&form_factor=mobile
[sri-hash]: https://www.srihash.org/
