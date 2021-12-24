cd /home/$(cat /etc/hostname)/
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
