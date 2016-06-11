FROM debian:jessie

ENV SIKTEERI_CONFIGURATION=dev
ENV LC_ALL=fi_FI.UTF-8

VOLUME /srv/apps/sikteeri
EXPOSE 8000

RUN apt-get update && apt-get install -qyy gettext libldap-dev libsasl2-dev python-dev python-pip libpq-dev python-virtualenv

ADD requirements.txt /tmp/requirements.txt
RUN mkdir -p /srv/venv && virtualenv --python=python2.7 /srv/venv/sikteeri && /srv/venv/sikteeri/bin/pip install -r /tmp/requirements.txt
RUN apt-get install -qyy locales && echo fi_FI UTF-8 >> /etc/locale.gen && locale-gen -a

RUN mkdir -p /srv/apps

RUN groupadd -g 1000 sikteeri && useradd -m -u 1000 -g 1000 sikteeri
WORKDIR /home/sikteeri

# Set up app
ADD . /srv/apps/sikteeri
RUN chmod a+rX -R /srv/venv/sikteeri /srv/apps/sikteeri
RUN /srv/venv/sikteeri/bin/python /srv/apps/sikteeri/manage.py migrate && \
    /srv/venv/sikteeri/bin/python /srv/apps/sikteeri/manage.py createsuperuser --username admin --email root@localhost --noinput && \
    /srv/venv/sikteeri/bin/python /srv/apps/sikteeri/manage.py loaddata /srv/apps/sikteeri/membership/fixtures/membership_fees.json && \
    /srv/venv/sikteeri/bin/python /srv/apps/sikteeri/manage.py generate_test_data

USER sikteeri
CMD [ "/srv/venv/sikteeri/bin/python", "/srv/apps/sikteeri/manage.py", "runserver", "0.0.0.0:8000" ]
