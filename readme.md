
#### firewall-cmd

```
firewall-cmd --state
firewall-cmd --get-active-zones

firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="172.28.200.2" port protocol="tcp" port="8081" accept'

firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" source address="172.28.200.0/24" port protocol="tcp" port="8081" accept'

firewall-cmd --permanent \
  --add-rich-rule='rule family="ipv4" port protocol="tcp" port="8081" drop'

firewall-cmd --reload

firewall-cmd --list-rich-rules

firewall-cmd --permanent \
  --remove-rich-rule='rule family="ipv4" source address="172.28.200.2" port protocol="tcp" port="8081" accept'

firewall-cmd --permanent \
  --remove-rich-rule='rule family="ipv4" port protocol="tcp" port="8081" drop'

```