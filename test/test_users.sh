source ../util/util.sh
source ../util/string-util.sh
source ../util/user-util.sh

# my_test "/opt/Talend/6.3.1/tac" "tac_admin" "tomcat"


myvar=" leading_space"
trim myvar
echo "myvar=|${myvar}|"

myvar="trailing_space "
trim myvar
echo "myvar=|${myvar}|"

 myvar="	leading_tab"
trim myvar
echo "myvar=|${myvar}|"

myvar="trailing_tab	"
trim myvar
echo "myvar=|${myvar}|"

#group_exists tomcat_ || echo "1 - tomcat_ does not exist" && echo "and condition"
! group_exists tomcat_admin && echo "2 - tomcat_admin does not exist" && echo "and condition"
#group_exists tomcat_admin && echo "3 - tomcat_admin exists"
