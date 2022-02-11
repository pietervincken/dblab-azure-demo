FROM postgresai/extended-postgres:11

# Workaround for Microsofts different naming of locale: https://docs.microsoft.com/en-gb/windows/win32/intl/locale-names?redirectedfrom=MSDN
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en-US