cd /home/$(cat /etc/hostname)/
mkdir /var/cw/systeam/.vim-backup > /dev/null 2>&1
cat <<- _EOF_ > /root/.vimrc
set backup
set backupdir=/var/cw/systeam/.vim-backup
set writebackup
set backupcopy=yes
au BufWritePre * let &bex = '@' . strftime("%F-%H-%M")
_EOF_



st() {
  if [[ -z "$ORIG" ]]; then
    ORIG=$PS1
  fi
  TITLE="\[\e]2;$*\a\]"
  PS1=${ORIG}${TITLE}
}

app () {
	grep -lr "$(echo -e "$1" | sed -e 's|^[^/]*//| |' -e 's|/.*$||')" */conf | awk -F "/" 'END{print $1}'
	}
wp () {
	/usr/local/bin/wp --allow-root $@
	}

dns () {
	host $(echo $1 | sed -e 's|^[^/]*//||' -e 's|/.*$||')
	}

master () {
	su $(grep master /etc/passwd | head -n 1 | cut -d ":" -f1)
	}

fixperm() {
	/usr/bin/curl -s https://raw.githubusercontent.com/aphraz/cloudways/master/permissions.sh?Sdsdads | /bin/bash
	}

slowlog() {
	for PID in $(awk '{print}' php-app.access.log | sort -nbrk 12,12 |  \
	head -n 20 | awk '{print $11}');do awk "/pid $PID/,/^$/" \
	php-app.slow.log;done
	}

pidmem () {
	gawk -v OFS="\t"  'BEGIN{printf("\n%s\t%s\n", "PID","Memory")} {SUM[$11] += $13} \
	END {for (s in SUM) printf("%d\t%.2f %s\n", s,SUM[s]/1024/1024,"MB") | \
	"sort -nbrk2,2 | head"}' php-app.access.log
	}

pidmemall () {
	for A in $(ls -l /home/master/applications/| grep "^d" | gawk '{print $NF}'); do \
	echo -e "\n" ; echo -e $A && gawk 'NR==1 {print substr($NF, 1, length($NF)-1)}' \
	/home/master/applications/$A/conf/server.nginx; awk -v OFS="\t"  \
	'BEGIN{printf("\n%s\t%s\n", "PID","Memory")} {SUM[$11] += $13} END {for (s in SUM) \
	printf("%d\t%.2f %s\n", s,SUM[s]/1024/1024,"MB") | "sort -nbrk2,2 | head"}' \
	/home/master/applications/$A/logs/php-app.access.log;done
	}

concurr () {
	watch -xtn 1 awk '$2 ~ /:01BB|:0050/ {count +=1;} END {print "Concurrent Web Traffic: ",count}' /proc/net/tcp
	}

list-restore () {
	for i in $(ls -l /home/master/applications/| grep "^d" | awk '{print $NF}'); do \
	echo Application: $i;/var/cw/scripts/bash/duplicity_restore.sh --src $i -c; done
	}

reset-services () {
	/etc/init.d/nginx restart
	/etc/init.d/varnish restart
	/etc/init.d/apache2 restart
	/etc/init.d/php$(php -v  | head -n 1 | cut -d " " -f2 | cut -d "." -f1,2)-fpm restart
	/etc/init.d/mysql restart
	/etc/init.d/memcached restart
	/etc/init.d/redis-server restart 2> /dev/null
	} 

sqlvars () {
	mysqladmin variables | tr -d " " | awk -F'|' '{print $2 " = " $3}'
	}
space-current() {
	du -shc ./* 2>/dev/null | sort -rh
}
space-var-log() {
	du -shc /var/log/* 2>/dev/null | sort -rh
}
space-mysql() {
	du -shc /var/lib/mysql/* 2>/dev/null | sort -rh
}
clear-log-php() {
	truncate -s 1000 /var/log/php$(php -v  | head -n 1 | cut -d " " -f2 | cut -d "." -f1,2)-fpm.log
}
apm-all-day() {
	cd /home/master/applications;for A in $(ls | awk '{print $NF}'); do echo $A && apm traffic -s $A -l 1d; done
}
apm-all-hour() {
	cd /home/master/applications;for A in $(ls | awk '{print $NF}'); do echo $A && apm traffic -s $A -l 1h; done
}
apm-all-min() {
	cd /home/master/applications;for A in $(ls | awk '{print $NF}'); do echo $A && apm traffic -s $A -l 15m; done
}
apm-app-day() {
	apm traffic -s $(grep -lr "$(echo -e "$1" | sed -e 's|^[^/]*//| |' -e 's|/.*$||')" */conf | awk -F "/" 'END{print $1}') -l 1d
}

apm-app-hour() {
	apm traffic -s $(grep -lr "$(echo -e "$1" | sed -e 's|^[^/]*//| |' -e 's|/.*$||')" */conf | awk -F "/" 'END{print $1}') -l 1h
}

apm-app-min() {
	apm traffic -s $(grep -lr "$(echo -e "$1" | sed -e 's|^[^/]*//| |' -e 's|/.*$||')" */conf | awk -F "/" 'END{print $1}') -l 15m
}
restart-nginx() {
	/etc/init.d/nginx restart
}
restart-php() {
	/etc/init.d/php$(php -v  | head -n 1 | cut -d " " -f2 | cut -d "." -f1,2)-fpm restart
}
restart-mysql() {
	/etc/init.d/mysql restart
}
restart-memcached() {
	/etc/init.d/memcached restart
}
restart-redis() { 
	/etc/init.d/redis-server restart 2> /dev/null
}
reset-services () {
	/etc/init.d/nginx restart
	/etc/init.d/varnish restart
	/etc/init.d/apache2 restart
	/etc/init.d/php$(php -v  | head -n 1 | cut -d " " -f2 | cut -d "." -f1,2)-fpm restart
	/etc/init.d/mysql restart
	/etc/init.d/memcached restart
	/etc/init.d/redis-server restart 2> /dev/null
}
mysql-create-dumps () {
	cd /home/master/applications;mkdir ../dumps;for A in $(ls | awk '{print $NF}'); do echo $A && mysqldump $A > ../dumps/$A ; done
}  
fastcgi-timeout() {
	cd /etc/apache2/fcgi/
	sed -i -e s'#</IfModule>#ProxyTimeout 3600\n</IfModule>#'g $(grep -lr "$(echo -e "$1" | sed -e 's|^[^/]*//| |' -e 's|/.*$||')" */conf | awk -F "/" 'END{print $1}').conf
	/etc/init.d/apache2 restart
	/etc/init.d/php$(php -v  | head -n 1 | cut -d " " -f2 | cut -d "." -f1,2)-fpm restart
}
find-inodes() {
	for i in ./*; do echo $i; find $i |wc -l; done
}
clear-inodes() { 
	find ./ -type f -mtime +1 -delete
}
sed-searchreplace() { 
	grep -lr '$1' | xargs sed -i 's|$1|$2|g'
}
create_php_info() { 
	echo "<?php
// Show all information, defaults to INFO_ALL
phpinfo();

?>" >> phpinfo.php

}
clear_wp_cache() {
	rm -rf ./wp-content/cache/*
	wp --skip-plugins --skip-themes cache flush all
	wp --skip-plugins --skip-themes redis flush all
	/etc/init.d/redis-server restart
	/etc/init.d/varnish restart
	/etc/init.d/nginx restart
}
clear_redis_varnish() { 
	/etc/init.d/redis-server restart
	/etc/init.d/varnish restart
}
get_domain() { 
	cat /home/master/applications/$1/conf/server.nginx
}
set_ansible() {
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEE3dYCZe/NwYuaCAZ/b1+ELDWqeNN1ozXXE7EuhYaSb8wQAZqTHtz1Ha+cRWwbQrXV6bVVnk4y3hV3/djkT1zq8mCzugyt1LI1oRlONRQrvUWb4/rkd1FpNT9Nu37Ds3X5GaylHLZMaptoWc6VFI9Utm97/3FCclCznIfhpNaq+nt2oLtkasLwDDb84qQt/Q12WYUyhrgtoRtHfG1DU+JOAfGwkV822fWTCfoQqx8ek3FbQaLxKb8CoQF91cQUhXaKYPDf+kwgCs9EiPM8XCk/WrgDXQeHGrOTJd/R+Ef6ecTxOKmOZu4NsoVUZdPMXL+PwqhJlheX0nrhOFcCJUDuoFm/ZAeIED2yUnpO2wlDLdtSpclbpFWqQCGsetVKCIGxYYrvvKI7KH74ZA8ddMEFQWpPkNhrMaJ7/yzZOg/s4sGMKaG2xmtm/leBlaVORBoQlQWn5t/rk6yl8ifdYnj7ae5dUqM3qJy+7SSF/pRQxI5Yo18mYeMUBjLAJAjemc= humair@clw-po-humair" >> /var/cw/ansible/.ssh/authorized_keys
	hostname
}

set_ansible_ssh_hosts() {
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwZY9rfWasvYNTC9s8LM3R81+lw6u/u3BB8H/mKvkIfsLFpLcIVwFkmsz8y9RQ0K/pCMUn57nyA4o/pezPGzRnGD2Th7sDmubbaVXr01po5zzZJdhln1o/pqozQxXjkSWMxRLMO7bYJV5EsBhyAiRTQLokCFoTCFrlNuYeXc1dQXjpvSPYEqFBq0ZRNINFl98/XtGq580BIV2cFGHrMfrLbmXRodHSzT+BFlZ9twrhSq/qYF0nTIoci6yOu0aoeToUkOJxGq7iZmzIzCIhrT5lkV+dXXte6rR852HMPhUpkuguFMErssGypleFMRpXQpLshC8lFRhNIK2M5xrbj5/n humair@clw-po-humair" >> /var/cw/ansible/.openssh/authorized_keys
	hostname
}
get_playbookversion() {
	cat /etc/ansible/facts.d/playbook_version.fact
}
