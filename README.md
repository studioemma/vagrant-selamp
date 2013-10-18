vagrant-selamp
=============

Simple lamp box for StudioEmma

Tips:
-----

### xhprof

to use xhprof add the following lines in your vhost file:

```
php_value auto_prepend_file /var/www/xhprof/header.php
php_value auto_append_file /var/www/xhprof/footer.php
```
