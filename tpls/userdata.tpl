if [ ! -f "/opt/cmp/config.properties" ]; then
  touch /opt/cmp/config.properties
  echo "cmp.provider.credential=vm-role://${instance_service_account}@gcp" >> /opt/cmp/config.properties
  echo 'cmp.provider.opsBucket=${automq_ops_bucket}' >> /opt/cmp/config.properties
  echo 'cmp.provider.instanceProfile=${instance_service_account}' >> /opt/cmp/config.properties
  echo 'cmp.environmentId=${environment_id}' >> /opt/cmp/config.properties
fi