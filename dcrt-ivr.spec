#
%define pkgname dcrt-ivr
%define filelist %{pkgname}-%{version}-filelist
%define NVR %{pkgname}-%{version}-%{release}
%define maketest 1

name:      dcrt-ivr
summary:   Dcrt IVR
version:   0.0.1
Release:   1
vendor:    Newtech-BT Ltd <support@newtech-bt.bg>
packager:  Newtech-BT Ltd <support@newtech-bt.bg>
license:   GPL
group:     Applications/Communications
url:       http://www.newtech-bt.bg
buildroot: %{_tmppath}/%{name}-%{version}-%(id -u -n)
buildarch: noarch
prefix:    %(echo %{_prefix})
Source:    %{name}-%{version}.tar.gz
AutoReqProv: no
Requires:  perl-AppConfig,perl-libwww-perl
Requires(post): chkconfig
Requires(preun): chkconfig
# This is for /sbin/service
Requires(preun): initscripts

%description
Dcrt IVR.

#
# This package was generated automatically with the cpan2rpm
# utility.  To get this software or for more information
# please visit: http://perl.arix.com/
#

%prep
%setup -q -n %{pkgname}-%{version} 
chmod -R u+w %{_builddir}/%{pkgname}-%{version}

%build
grep -rsl '^#!.*perl' . |
grep -v '.bak$' |xargs --no-run-if-empty \
%__perl -MExtUtils::MakeMaker -e 'MY->fixin(@ARGV)'
%{__perl} Build.PL
%{__perl} Build
%if %maketest
%{__perl} Build test
%endif

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%{__perl} Build install destdir=%{buildroot}

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress


# remove special files
find %{buildroot} -name "perllocal.pod" \
    -o -name ".packlist"                \
    -o -name "*.bs"                     \
    |xargs -i rm -f {}

# no empty directories
find %{buildroot}%{_prefix}             \
    -type d -depth                      \
    -exec rmdir {} \; 2>/dev/null

%{__perl} -MFile::Find -le '
    find({ wanted => \&wanted, no_chdir => 1}, "%{buildroot}");
    print "";
    for my $x (sort @dirs, @files) {
        push @ret, $x unless indirs($x);
        }
    print join "\n", sort @ret;

    sub wanted {
        return if /auto$/;

        local $_ = $File::Find::name;
        my $f = $_; s|^\Q%{buildroot}\E||;
        return unless length;
        return $files[@files] = $_ if -f $f;

        $d = $_;
        /\Q$d\E/ && return for reverse sort @INC;
        $d =~ /\Q$_\E/ && return
            for qw|/etc %_prefix/man %_prefix/bin %_prefix/share|;

        $dirs[@dirs] = $_;
        }

    sub indirs {
        my $x = shift;
        $x =~ /^\Q$_\E\// && $x ne $_ && return 1 for @dirs;
        }
    ' > %filelist

[ -z %filelist ] && {
    echo "ERROR: empty %files listing"
    exit -1
    }

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files -f %filelist
%defattr(-,root,root)
%config /etc/rc.d/init.d/agid
%config /etc/sysconfig/agid
%config /etc/agid.conf

%pre

%post
# This adds the proper /etc/rc*.d links for the script
/sbin/chkconfig --add agid

%preun
if [ $1 -eq 0 ] ; then
    /sbin/service agid stop >/dev/null 2>&1
    /sbin/chkconfig --del agid
fi

%postun
if [ "$1" -ge "1" ] ; then
    /sbin/service agid condrestart >/dev/null 2>&1 || :
fi

%changelog
* Mon Jan 19 2015 Georgi Manev, 0.0.1
- initial release

