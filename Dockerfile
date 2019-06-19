FROM crutonjohn/mod_gearman:latest

COPY oracle*.rpm oracleinstall.sh worker.conf /tmp/

# install deps
RUN export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:/root/perl5" && \
export PERL_MB_OPT="--install_base /root/perl5" && \
export PERL_MM_OPT="INSTALL_BASE=/root/perl5" && \
export PERL5LIB="/root/perl5/lib/perl5:$PERL5LIB" && \
export PATH="/root/perl5/bin:$PATH" && \
cd /tmp && \
chmod +x /tmp/oracleinstall.sh && \
/tmp/oracleinstall.sh && \
chmod +x /tmp/entrypoint.sh

ENTRYPOINT [ "/tmp/entrypoint.sh" ]
