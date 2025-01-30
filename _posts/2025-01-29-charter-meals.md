---
layout: post
title:  "Adding CharterMeals to My OpenBSD Server"
date:   2025-01-29 19:30:00 -0400
---
I recently decided to host an additional website, [chartermeals.com][cm-website], on the same OpenBSD VPS where I run [conjfrnk.com][cf-website]. Here's how.

Just like [last time][orig-site-post], I stuck to a bare-bones approach—no extra frameworks, only OpenBSD’s built-in tools (httpd, relayd, acme-client). Below is a rundown of how I set it up.

## How I got the server/website
As before, I used Epik to register my new domain and manage DNS. I added A/AAAA records for chartermeals.com (and www.chartermeals.com) pointing to the same server IP addresses I use for conjfrnk.com.

## About the website
- Hosted on OpenBSD using httpd (no 3rd-party tools were installed at all)
- https using relayd and acme
- No frameworks, just plain `index.html` and `style.css`

## Source files
I have backed up all of the source files for the website itself to [this repository][git-repo]

## Config files
### `/etc/acme-client.conf`
Since I already have acme-client set up for Let’s Encrypt certificates, I only needed to add another domain block:
{% highlight conf %}
domain chartermeals.com {
       alternative names { www.chartermeals.com }
       domain key "/etc/ssl/private/chartermeals.com.key"
       domain full chain certificate "/etc/ssl/chartermeals.com.crt"
       sign with letsencrypt
}
{% endhighlight %}

### `/etc/httpd.conf`
{% highlight conf %}
server "chartermeals.com" {
    listen on 127.0.0.1 port 8080
    root "/htdocs/www.chartermeals.com"
    gzip-static

    location "/.well-known/acme-challenge/*" {
        root "/acme"
        request strip 2
    }

    location match "/([^.]+)$" {
        request rewrite "/%1.html"
    }
}

server "www.chartermeals.com" {
    listen on 127.0.0.1 port 8080
    block return 301 "https://chartermeals.com$REQUEST_URI"
}

server "chartermeals.com" {
    listen on * port 80
    alias "www.chartermeals.com"
    block return 301 "https://chartermeals.com$REQUEST_URI"
}
{% endhighlight %}
Just like with conjfrnk.com, port 80 connections get redirected to HTTPS, and www.chartermeals.com redirects to the main domain.

### `/etc/relayd.conf`
I’m still using relayd to terminate TLS. To serve the new certificate, I added another tls keypair line:
{% highlight conf %}
http protocol https {
    tls keypair "conjfrnk.com"
    tls keypair "chartermeals.com"
    ...
}
{% endhighlight %}


[cm-website]: https://chartermeals.com
[cf-website]: https://conjfrnk.com
[orig-site-post]: https://conjfrnk.github.io/2024/04/15/my-website/
[git-repo]: https://github.com/conjfrnk/charter-meals
