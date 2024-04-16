#!/usr/bin/env python3
"""
Fetch json dashboards from provided path and convert into a ConfigMaps.
"""
import json
import re
import textwrap
from os import makedirs
import yaml
from yaml.representer import SafeRepresenter
import logging
import os
import sys

log_level = os.environ.get('LOGLEVEL', 'INFO').upper()
logging.basicConfig(stream=sys.stderr, level=log_level, format='%(asctime)s %(levelname)s %(message)s')


# https://stackoverflow.com/a/20863889/961092
class LiteralStr(str):
    pass


def change_style(style, representer):
    def new_representer(dumper, data):
        scalar = representer(dumper, data)
        scalar.style = style
        return scalar

    return new_representer


# Additional conditions map
condition_map = {
    'grafana-coredns-k8s': ' .Values.coreDns.enabled',
    'etcd': ' .Values.kubeEtcd.enabled',
    'apiserver': ' .Values.kubeApiServer.enabled',
    'controller-manager': ' .Values.kubeControllerManager.enabled',
    'kubelet': ' .Values.kubelet.enabled',
    'proxy': ' .Values.kubeProxy.enabled',
    'scheduler': ' .Values.kubeScheduler.enabled',
    'node-rsrc-use': ' .Values.nodeExporter.enabled',
    'node-cluster-rsrc-use': ' .Values.nodeExporter.enabled',
    'nodes': ' .Values.nodeExporter.enabled',
    'nodes-darwin': ' .Values.nodeExporter.enabled',
    'prometheus-remote-write': ' .Values.prometheus.prometheusSpec.remoteWriteDashboards'
}

# standard header
header = '''{{- /*
Generated from json dashboard '%(url)s/%(name)s.json'.
Do not change in-place! In order to change this file first modify the json dashboard '%(url)s/%(name)s.json'
and then run the 'scripts/convert-dashboard/convert-dashboard.py' script.
*/ -}}
{{- $kubeTargetVersion := default .Capabilities.KubeVersion.GitVersion .Values.kubeTargetVersionOverride }}
{{- if and 
    (index .Values "products" "%(dashboard_type)s" "enabled")
    (index .Values "products" "%(dashboard_type)s" "dashboards" "%(name)s" "enabled")
    (index .Values "products" "%(dashboard_type)s" "dashboards" "%(name)s" "yamlVersion")
    (not .Values.forceDeployJsonDashboards)
    (semverCompare ">=%(min_kubernetes)s" $kubeTargetVersion)
    (semverCompare "<%(max_kubernetes)s" $kubeTargetVersion)
    %(condition)s 
}}
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: {{ template "cognigy-dashboards.namespace" . }}
  name: {{ printf "%%s-%%s" (include "cognigy-dashboards.fullname" $) "%(name)s" | trunc 63 | trimSuffix "-" }}
  {{- with $.Values.grafana.sidecar.dashboards.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  labels:
    {{- if $.Values.grafana.sidecar.dashboards.label }}
    {{ $.Values.grafana.sidecar.dashboards.label }}: {{ ternary $.Values.grafana.sidecar.dashboards.labelValue "1" (not (empty $.Values.grafana.sidecar.dashboards.labelValue)) | quote }}
    {{- end }}
    app: {{ template "cognigy-dashboards.name" $ }}-grafana
    {{- include "cognigy-dashboards.labels" $ | nindent 4 }}
data:
'''

# Source files list
with open('var.yaml', 'r') as local_charts_file:
    dashboards = yaml.load(local_charts_file, Loader=yaml.SafeLoader)

# cluster variable
with open('cluster-variable.json') as cluster_variable_file:
    cluster_variable = json.load(cluster_variable_file)

# datasource variable
with open('datasource-variable.json') as datasource_variable_file:
    datasource_variable = json.load(datasource_variable_file)


def init_yaml_styles():
    represent_literal_str = change_style('|', SafeRepresenter.represent_str)
    yaml.add_representer(LiteralStr, represent_literal_str)


def yaml_str_repr(struct, indent=2):
    """represent yaml as a string"""
    text = yaml.dump(
        struct,
        width=1000,  # to disable line wrapping
        default_flow_style=False  # to disable multiple items on single line
    )
    text = textwrap.indent(text, ' ' * indent)
    return text


def patch_dashboards_json(content, multicluster_key, dashboard_type, resource_name):
    try:
        content_struct = json.loads(content)

        override_list = []
        cluster_variable_exist = False
        datasource_variable_exist = False

        logging.debug(f'Title: {content_struct["title"]}')
        if 'refresh' in content_struct:
            logging.debug(f'refresh is already defined with {content_struct["refresh"]}, going to parameterize it.')
        content_struct['refresh'] = ':refresh:'

        if 'time' in content_struct:
            logging.debug(f'time is already defined with {content_struct["time"]}, going to parameterize it.')
        content_struct['time'] = {
            "from": ":time_from:",
            "to": "now"
        }

        for variable in content_struct['templating']['list']:
            logging.debug(f"Checking {variable['name']} variable")
            variable['current'] = {
                "text": "",
                "value": ""
            }

            if variable['name'] == 'cluster':
                variable['hide'] = ':multicluster:'
                cluster_variable_exist = True
                logging.debug('cluster variable exists')

            # set the datasource variable name to "datasource"
            if variable['type'] == 'datasource':
                variable['name'] = 'datasource'
                variable['label'] = 'Data Source'
                datasource_variable_exist = True
                logging.debug('datasource exists')

            if not variable['type'] == 'datasource':
                logging.debug(f'Updating datasource of {variable["name"]} variable')
                variable['datasource'] = {
                    "type": "prometheus",
                    "uid": "$datasource"
                }

            override_list.append(variable)

        for panel in content_struct['panels']:

            """
            Set 
                panel['datasource'] = {
                    "type": "prometheus",
                    "uid": "$datasource"
                }
            1. When datasource is not defined for a panel at all
            2. When datasource.uid is defined but not set to 'datasource_exception_list'
            3. When datasource.uid is not defined

            Same logic for each 'targets' in a panel.
            """
            datasource_exception_list = ['grafana', '__expr__']
            if 'datasource' not in panel:
                logging.debug(f'Adding datasource of panel')
                panel['datasource'] = {
                    "type": "prometheus",
                    "uid": "$datasource"
                }
            else:
                if type(panel['datasource']) is dict:
                    if 'uid' in panel['datasource']:
                        if panel['datasource']['uid'] not in datasource_exception_list:
                            logging.debug(f'Adding uid to datasource of panel')
                            panel['datasource'] = {
                                "type": "prometheus",
                                "uid": "$datasource"
                            }
                else:
                    logging.debug(f'Updating datasource of panel')
                    panel['datasource'] = {
                        "type": "prometheus",
                        "uid": "$datasource"
                    }

            if 'targets' in panel:
                logging.debug(f'Checking datasource of targets in panel')
                for target in panel['targets']:
                    if 'datasource' not in target:
                        logging.debug(f'Adding datasource of targets in panel')
                        target['datasource'] = {
                            "type": "prometheus",
                            "uid": "$datasource"
                        }
                    else:
                        if type(target['datasource']) is dict:
                            if 'uid' in target['datasource']:
                                if target['datasource']['uid'] not in datasource_exception_list:
                                    logging.debug(f'Adding uid to datasource of targets in panel')
                                    target['datasource'] = {
                                        "type": "prometheus",
                                        "uid": "$datasource"
                                    }
                        else:
                            logging.debug(f'Updating datasource of targets in panel')
                            target['datasource'] = {
                                "type": "prometheus",
                                "uid": "$datasource"
                            }

        logging.debug(f'Cluster variable already exists?: {cluster_variable_exist}')
        if not cluster_variable_exist:

            logging.debug('Adding cluster variable')
            cluster_variable['hide'] = ':multicluster:'
            override_list = [cluster_variable] + override_list

        logging.debug(f'Datasource variable already exists?: {datasource_variable_exist}')
        if not datasource_variable_exist:
            logging.debug('Adding datasource variable')
            override_list = [datasource_variable] + override_list

        content_struct['timezone'] = '{{ .Values.grafana.defaultDashboardsTimezone }}'
        content_struct['templating']['list'] = override_list

        content = json.dumps(content_struct, separators=(',', ': '), indent=2, sort_keys=True)
        content = content.replace(
            '":multicluster:"',
            '{{ if %s }}0{{ else }}2{{ end }}' % multicluster_key
        )
        content = content.replace(
            ':refresh:',
            f'{{{{ index .Values "products" "{dashboard_type}" "dashboards" "{resource_name}" "refreshInterval" | default "5m" }}}}'
        )
        content = content.replace(
            ':time_from:',
            f'{{{{ index .Values "products" "{dashboard_type}" "dashboards" "{resource_name}" "timeFrom" | default "now-3h" }}}}'
        )

    except Exception as e:
        logging.error(f'Exception in patch_dashboards_json: {e}')

    return json.dumps(content, indent=2)


def patch_json_set_timezone_as_variable(content):
    logging.debug('Parameterizing timezone variable')
    # content is no more in json format, so we have to replace using regex
    return re.sub(r'"timezone"\s*:\s*"(?:\\.|[^\"])*"',
                  '"timezone": "{{ .Values.grafana.defaultDashboardsTimezone }}"',
                  content,
                  flags=re.IGNORECASE)


def patch_double_curly_brackets(content):
    logging.debug('Updating dashboard so that helm can handle curly brackets')
    content = re.sub(r'{{', ':opening_bracket:', content, flags=re.IGNORECASE)
    content = re.sub(r'}}', ':closing_bracket:', content, flags=re.IGNORECASE)
    content = re.sub(r':opening_bracket:', '{{`{{`}}', content, flags=re.IGNORECASE)
    content = re.sub(r':closing_bracket:', '{{`}}`}}', content, flags=re.IGNORECASE)

    return content


def write_group_to_file(resource_name,
                        content,
                        url,
                        dashboard_type,
                        destination,
                        min_kubernetes,
                        max_kubernetes,
                        multicluster_key):

    # initialize header
    lines = header % {
        'name': resource_name,
        'url': url.replace('../', ''),
        'condition': condition_map.get(resource_name, ''),
        'min_kubernetes': min_kubernetes,
        'max_kubernetes': max_kubernetes,
        'dashboard_type': dashboard_type
    }

    content = patch_double_curly_brackets(content)
    content = patch_dashboards_json(content, multicluster_key, dashboard_type, resource_name)
    content = patch_json_set_timezone_as_variable(content)

    filename_struct = {resource_name + '.json': (LiteralStr(json.loads(content)))}
    # rules themselves
    lines += yaml_str_repr(filename_struct)

    # footer
    lines += '{{- end }}'

    filename = resource_name + '.yaml'
    new_filename = "%s/%s" % (destination, filename)

    # make sure directories to store the file exist
    makedirs(destination, exist_ok=True)

    if os.path.isfile(new_filename):
        logging.info('%s already exists. Going to update it' % new_filename)
    else:
        logging.info('Creating new file %s' % new_filename)

    # recreate the file
    with open(new_filename, 'w') as f:
        f.write(lines)

    logging.info('Generated %s' % new_filename)


def main():
    init_yaml_styles()

    # read the input var file, create a new template file per group
    for dashboard in dashboards['dashboards']:

        if 'min_kubernetes' not in dashboard:
            dashboard['min_kubernetes'] = '1.14.0-0'

        if 'max_kubernetes' not in dashboard:
            dashboard['max_kubernetes'] = '9.9.9-9'

        if 'source' not in dashboard:
            dashboard['source'] = f"../../dashboards/{dashboard['dashboard_type']}"

        if 'destination' not in dashboard:
            dashboard['destination'] = '../../templates/dashboards'

        if 'multicluster_key' not in dashboard:
            dashboard['multicluster_key'] = '.Values.grafana.sidecar.dashboards.multicluster.global.enabled'

        logging.info(f"Generating dashboard from {dashboard['source']}/{dashboard['name']}.json")

        with open(f"{dashboard['source']}/{dashboard['name']}.json") as f:
            raw_text = json.load(f)

        write_group_to_file(resource_name=dashboard['name'],
                            content=json.dumps(raw_text, indent=2),
                            url=dashboard['source'],
                            dashboard_type=dashboard["dashboard_type"],
                            destination=f"{dashboard['destination']}/{dashboard['dashboard_type']}",
                            min_kubernetes=dashboard['min_kubernetes'],
                            max_kubernetes=dashboard['max_kubernetes'],
                            multicluster_key=dashboard['multicluster_key']
                            )
        logging.debug('Finished')


if __name__ == '__main__':
    main()
