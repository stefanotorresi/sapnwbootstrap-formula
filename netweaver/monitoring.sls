{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

prometheus_sap_host_exporter_pkg:
  pkg.installed:
    - name: prometheus-sap_host_exporter

# the sid, instance number pair of a node is unique, so we need to adapt configuration
{% for node in netweaver.nodes if host == node.host and node.sap_instance != "db" %}
{% set instance = '{:0>2}'.format(node.instance) %}
{% set daemon_instance = '{}_{}'.format(node.sid, instance) %}

sap_host_exporter_service_{{ daemon_instance }}:
  service.running:
    - name: prometheus-sap_host_exporter@{{ daemon_instance }}
    - enable: True
    - restart: True
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
      - file: sap_host_exporter_configuration_{{ daemon_instance }}
    - watch:
      - file: sap_host_exporter_configuration_{{ daemon_instance }}


# we can have multiple exporters in the same host in that moment, we need to change the port used by the exporter
sap_host_exporter_configuration_{{ daemon_instance }}:
  file.managed:
    - name: /etc/sap_host_exporter/{{ daemon_instance }}.yaml
    - contents: |
         port: "968{{ loop.index0 }}"
         address: "0.0.0.0"
         log-level: "info"
         sap-control-url: "http://127.0.0.1:5{{ instance }}13"
         sap-control-user: "{{ node.sid.lower() }}adm"
         sap-control-password: "{{ netweaver.sid_adm_password|default(netweaver.master_password) }}"
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
{% endfor %}
