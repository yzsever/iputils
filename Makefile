#
# Configuration
#

# CC
#指定gcc程序
CC=gcc
# Path to parent kernel include files directory
LIBC_INCLUDE=/usr/include
# Libraries
ADDLIB=
# Linker flags
# wl选项告诉编辑器将后面的参数传递给链接器

LDFLAG_STATIC=-Wl,-Bstatic
#-wl，-Bstatic告诉链接器使用-Bstatic选项，该选项是告诉链接器，对接下来的-l选项使用静态链接
LDFLAG_DYNAMIC=-Wl,-Bdynamic
#-Wl,-Bdynamic就是告诉链接器对接下来的-l选项使用动态链接
#指定加载库
LDFLAG_CAP=-lcap
LDFLAG_GNUTLS=-lgnutls-openssl
#libgnutls-openssl是一个libtool库文件
LDFLAG_CRYPTO=-lcrypto
LDFLAG_IDN=-lidn
LDFLAG_RESOLV=-lresolv
LDFLAG_SYSFS=-lsysfs

#
# Options
#
#变量定义。设置开关
# Capability support (with libcap) [yes|static|no]
USE_CAP=yes
# sysfs support (with libsysfs - deprecated) [no|yes|static]
USE_SYSFS=no
# IDN support (experimental) [no|yes|static]
USE_IDN=no

# Do not use getifaddrs [no|yes|static]
WITHOUT_IFADDRS=no
# arping default device (e.g. eth0) []
ARPING_DEFAULT_DEVICE=

# GNU TLS library for ping6 [yes|no|static]
#允许ping6使用TLS加密的函数库
USE_GNUTLS=yes
# Crypto library for ping6 [shared|static]
#和ping6共享Crypto库，Crypto库是一个密码库
USE_CRYPTO=shared
# Resolv library for ping6 [yes|static]
USE_RESOLV=yes
# ping6 source routing (deprecated by RFC5095) [no|yes|RFC3542]
ENABLE_PING6_RTHDR=no

# rdisc server (-r option) support [no|yes]
ENABLE_RDISC_SERVER=no

# -------------------------------------
# What a pity, all new gccs are buggy and -Werror does not work. Sigh.
# CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -Werror -g
#-Wstrict-prototypes: 如果函数的声明或定义没有指出参数类型，编译器就发出警告
CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -g
CCOPTOPT=-O3
#使用3级优化
GLIBCFIX=-D_GNU_SOURCE
DEFINES=
LDLIB=

#下面这句话涉及到了两个重要的函数，filter过滤函数，和if条件判断函数，if与ifeq表达式功能相同
#$(filter<pattern...>,<text>)  以<pattern>模式过滤<text>字符串中的单词，保留符合模式的。 下面语句就是过滤出$(1)中的静态变量
#$(if <condition>,<then-part>,<else-part>) 表达式为真，执行then-part,否则执行else-part
#下面语句的解释为，如果$(1)中的静态变量和$(LDFLAG_STATIC)相同，则将$(2)和$(LDFLAG_DYNAMIC)赋值给FUNC_LIB，否则用$(2)赋值
FUNC_LIB = $(if $(filter static,$(1)),$(LDFLAG_STATIC) $(2) $(LDFLAG_DYNAMIC),$(2))

# USE_GNUTLS: DEF_GNUTLS, LIB_GNUTLS
# USE_CRYPTO: LIB_CRYPTO
#下面是条件判断语句，ifneq用法是：如果后面的两个参数的值不相同，则表达式为真，执行语句
ifneq ($(USE_GNUTLS),no)
	LIB_CRYPTO = $(call FUNC_LIB,$(USE_GNUTLS),$(LDFLAG_GNUTLS))
#call函数为用户创建一个自定义的函数，FUNC_LIB中的参数被$(USE_GNUTLS),$(LDFLAG_GNUTLS)取代
	DEF_CRYPTO = -DUSE_GNUTLS
#由于之前已给USE_GNUTS赋值为yes，所以可以执行库的调用
else
	LIB_CRYPTO = $(call FUNC_LIB,$(USE_CRYPTO),$(LDFLAG_CRYPTO))
endif

# USE_RESOLV: LIB_RESOLV
LIB_RESOLV = $(call FUNC_LIB,$(USE_RESOLV),$(LDFLAG_RESOLV))

# USE_CAP:  DEF_CAP, LIB_CAP
ifneq ($(USE_CAP),no)
	DEF_CAP = -DCAPABILITIES
	LIB_CAP = $(call FUNC_LIB,$(USE_CAP),$(LDFLAG_CAP))
endif

# USE_SYSFS: DEF_SYSFS, LIB_SYSFS
ifneq ($(USE_SYSFS),no)
	DEF_SYSFS = -DUSE_SYSFS
	LIB_SYSFS = $(call FUNC_LIB,$(USE_SYSFS),$(LDFLAG_SYSFS))
endif

# USE_IDN: DEF_IDN, LIB_IDN
ifneq ($(USE_IDN),no)
	DEF_IDN = -DUSE_IDN
	LIB_IDN = $(call FUNC_LIB,$(USE_IDN),$(LDFLAG_IDN))
endif

# WITHOUT_IFADDRS: DEF_WITHOUT_IFADDRS
ifneq ($(WITHOUT_IFADDRS),no)
	DEF_WITHOUT_IFADDRS = -DWITHOUT_IFADDRS
endif

# ENABLE_RDISC_SERVER: DEF_ENABLE_RDISC_SERVER
ifneq ($(ENABLE_RDISC_SERVER),no)
	DEF_ENABLE_RDISC_SERVER = -DRDISC_SERVER
endif

# ENABLE_PING6_RTHDR: DEF_ENABLE_PING6_RTHDR
ifneq ($(ENABLE_PING6_RTHDR),no)
	DEF_ENABLE_PING6_RTHDR = -DPING6_ENABLE_RTHDR
ifeq ($(ENABLE_PING6_RTHDR),RFC3542)
	DEF_ENABLE_PING6_RTHDR += -DPINR6_ENABLE_RTHDR_RFC3542
endif
endif

# -------------------------------------
#使用变量可以大大简化makefile的书写，使用变量的时候在变量之前加$,如下面的$(IPV4_TARGETS),而下面第一句=后面的tracepath则为变量中的变量
#makefile中用变量构造变量的值有三种方式：1、用“=” 2、用“：=”可以避免递归定义的危险，前的定义的变量不能使用后面定义的变量 
#3、“？=”如果之前变量的值没有定义过则可以定义，定义过则无法定义。
IPV4_TARGETS=tracepath ping clockdiff rdisc arping tftpd rarpd
IPV6_TARGETS=tracepath6 traceroute6 ping6
TARGETS=$(IPV4_TARGETS) $(IPV6_TARGETS)
# taggets后面的是所要生成的目标文件

CFLAGS=$(CCOPTOPT) $(CCOPT) $(GLIBCFIX) $(DEFINES)
LDLIBS=$(LDLIB) $(ADDLIB)

#$(shell <commmand>,<parm1>,<parm2>,...) <command>表示需要执行的shell命令，后面的<parm1>...为该shell命令的参数该函数的返回值为执行的shell命令的输出结果
UNAME_N:=$(shell uname -n)
#赋值UNAME_N网络主机的名称
LASTTAG:=$(shell git describe HEAD | sed -e 's/-.*//')
#将HEAD中的-.*替换为/
TODAY=$(shell date +%Y/%m/%d)
#按指定的格式%Y/%m/%d赋值给TODAY
DATE=$(shell date --date $(TODAY) +%Y%m%d)
#将TODAY中的内容以%Y%m%d赋值给DATE
TAG:=$(shell date --date=$(TODAY) +s%Y%m%d)
#将TODAY中的以字符串显示的时间赋值给TAG

# -------------------------------------
.PHONY: all ninfod clean distclean man html check-kernel modules snapshot
# .PHONY 伪目标 执行时前面要make

all: $(TARGETS)

%.s: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -S -o $@
%.o: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -o $@
$(TARGETS): %: %.o
	$(LINK.o) $^ $(LIB_$@) $(LDLIBS) -o $@

# COMPILE.c=$(CC) $(CFLAGS) $(CPPFLAGS) -c
# $< 依赖目标中的第一个目标名字 
# $@ 表示目标
# $^ 所有的依赖目标的集合 
# 在$(patsubst %.o,%,$@ )中，patsubst把目标中的变量符合后缀是.o的全部删除,  DEF_ping
# $(patsubst %.o,%,test1.o test2.o)执行结果是test1,test2
# LINK.o把.o文件链接在一起的命令行,缺省值是$(CC) $(LDFLAGS) $(TARGET_ARCH)
#函数patsubst:匹配替换，有三个参数。第一个是一个需要匹配的式样，第二个表示用什么来替换它，第三个是一个需要被处理的由空格分隔的列表。
#以ping为例，翻译为：e
# gcc -O3 -fno-strict-aliasing -Wstrict-prototypes -Wall -g -D_GNU_SOURCE    -c ping.c -DCAPABILITIES   -o ping.o
#gcc   ping.o ping_common.o -lcap    -o ping



# -------------------------------------
# arping
DEF_arping = $(DEF_SYSFS) $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS)
LIB_arping = $(LIB_SYSFS) $(LIB_CAP) $(LIB_IDN)

ifneq ($(ARPING_DEFAULT_DEVICE),)
DEF_arping += -DDEFAULT_DEVICE=\"$(ARPING_DEFAULT_DEVICE)\"
#“+=”表示给变量追加值。
endif

# clockdiff
# 对函数clockdiff进行设置
DEF_clockdiff = $(DEF_CAP)
LIB_clockdiff = $(LIB_CAP)

# ping / ping6
# 为ping/ping6指定库
DEF_ping_common = $(DEF_CAP) $(DEF_IDN)
DEF_ping  = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS)
LIB_ping  = $(LIB_CAP) $(LIB_IDN)
DEF_ping6 = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS) $(DEF_ENABLE_PING6_RTHDR) $(DEF_CRYPTO)
LIB_ping6 = $(LIB_CAP) $(LIB_IDN) $(LIB_RESOLV) $(LIB_CRYPTO)

#规定目标文件的依赖关系
ping: ping_common.o
ping6: ping_common.o
ping.o ping_common.o: ping_common.h
ping6.o: ping_common.h in6_flowlabel.h

# rarpd
DEF_rarpd =
LIB_rarpd =

# rdisc
DEF_rdisc = $(DEF_ENABLE_RDISC_SERVER)
LIB_rdisc =

# tracepath
DEF_tracepath = $(DEF_IDN)
LIB_tracepath = $(LIB_IDN)

# tracepath6
DEF_tracepath6 = $(DEF_IDN)
LIB_tracepath6 =

# traceroute6
DEF_traceroute6 = $(DEF_CAP) $(DEF_IDN)
LIB_traceroute6 = $(LIB_CAP) $(LIB_IDN)

# tftpd
DEF_tftpd =
DEF_tftpsubs =
LIB_tftpd =

#指明tftpd和tftpd.o,subs.o的依赖文件
tftpd: tftpsubs.o
tftpd.o tftpsubs.o: tftp.h

# -------------------------------------
# ninfod
ninfod:
	@set -e; \    #这边的\表示换行，是为了便于makefile的读和理解
#如果文件夹ninfod中没有Makefile文件，则进入文件夹执行configure生成Makefile，如果有则退出文件夹回到上层目录
		if [ ! -f ninfod/Makefile ]; then \
			cd ninfod; \
			./configure; \
			cd ..; \
		fi; \
#
		$(MAKE) -C ninfod
#表示进入ninfod目录执行makefile
# -------------------------------------
# modules / check-kernel are only for ancient kernels; obsolete
#检查内核
#如果如果内核头文件为空，则提示重新设置
check-kernel:
ifeq ($(KERNEL_INCLUDE),)
	@echo "Please, set correct KERNEL_INCLUDE"; false
else
#如果找不到autoconf.h不是普通文件，提示错误，重新设置
	@set -e; \
	if [ ! -r $(KERNEL_INCLUDE)/linux/autoconf.h ]; then \
		echo "Please, set correct KERNEL_INCLUDE"; false; fi
endif

#进入Modules执行Makefile
modules: check-kernel
	$(MAKE) KERNEL_INCLUDE=$(KERNEL_INCLUDE) -C Modules

# -------------------------------------
#生成man的帮助文档
man:
	$(MAKE) -C doc man

#生成html的帮助文档
html:
	$(MAKE) -C doc html

clean:
#删除Targets中的所有.o文件
	@rm -f *.o $(TARGETS)
#执行Modules中的clean
	@$(MAKE) -C Modules clean
#执行doc中的clean
	@$(MAKE) -C doc clean
	@set -e; \
#查看ninfod中是否有makefile文件，如果有，执行其中的clean
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod clean; \
		fi

distclean: clean
#查看ninfod中是否有makefile文件，如果有，清除所有生成的文件
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod distclean; \
		fi

# -------------------------------------
snapshot:
#如果UNAME_N和pleiades的十六进制不等，提示错误信息后退出。
	@if [ x"$(UNAME_N)" != x"pleiades" ]; then echo "Not authorized to advance snapshot"; exit 1; fi
#将TAG变量的内容重定向到RELNOTES.NEW文档中。
#>表示重定向 >>表示追加
	@echo "[$(TAG)]" > RELNOTES.NEW
#输出一个空行到RELNOTES.NEW文档中。
	@echo >>RELNOTES.NEW
#将git log和git shortlog的输出信息重定向到RELOTES.NEW文档里。
	@git log --no-merges $(LASTTAG).. | git shortlog >> RELNOTES.NEW

	@echo >> RELNOTES.NEW
#将RELNOTES里的内容重定向的RELNOTES.NEW文档里。	
	@cat RELNOTES >> RELNOTES.NEW
#重命名操作，RELNOTES.NEW命名为RELNOTES
	@mv RELNOTES.NEW RELNOTES
#将iputils.spec中的^%define ssdate .*替换成%define ssdate $(DATE)重定向到iputils.spec.tmp
	@sed -e "s/^%define ssdate .*/%define ssdate $(DATE)/" iputils.spec > iputils.spec.tmp
#重命名
	@mv iputils.spec.tmp iputils.spec
#将TAG变量中的内容以"static char SNAPSHOT[] = \"$(TAG)\"的形式重定向到SNAPSHOT.h文档中
	@echo "static char SNAPSHOT[] = \"$(TAG)\";" > SNAPSHOT.h
#生成snapshot的帮助文档
	@$(MAKE) -C doc snapshot
	@$(MAKE) man
#上交修改信息
	@git commit -a -m "iputils-$(TAG)"
#创建带有说明的标签，GPG来签署标签（需要有私钥，用-s）
	@git tag -s -m "iputils-$(TAG)" $(TAG)
#将iputils_$(TAG)打包
	@git archive --format=tar --prefix=iputils-$(TAG)/ $(TAG) | bzip2 -9 > ../iputils-$(TAG).tar.bz2

