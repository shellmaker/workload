#!/bin/ksh

	# Finalidade	: Instalacao do CTM/Agent800
	# Input		: $0 <PACOTE DE INSTALACAO>
	# Output	: Define User/Group, Dir, Agent TCP/ports. 
	# Autor		: Marcos de Benedicto
	# Cliente	: NET Servicos
	# Atualizacao	:

DIR_WRK="/app/incontrol/ag/ag800"
INST_PKG=$1
INST_XML="${DIR_WRK}/install_ag.xml"

set +x
echo "
Pacote de instalacao informado ${INST_PKG}
Versao do Linux: $(cat /etc/redhat-release)

Caso a versao de Linux seja 6 ou superior
 as seguintes LIBS devem ser instaladas antes:

#yum install pam.i686 krb5-libs.i686 glibc.i686 libcom_err.i686 libidn.i686 libstdc++.i686 

Continuar a instalacao? (y/N)"
read CHK
[ ${CHK} != y ] && exit 0


[ -d "${DIR_WRK}" ] && rm -rf ${DIR_WRK}

echo "

	+------------------------------------------------------------
	|  
	|  Preparando instacao do CTM/Agent para $(uname).
	|
	+------------------------------------------------------------\n"

sleep 2

set -x

pkill -9 p_ctmag
pkill -9 p_ctmat
userdel ag800

set +x
echo "
	+------------------------------------------------------------
	|  
	|  Definindo grupo \"controlm\" e usuario \"ag800\"
	|
	+------------------------------------------------------------\n"
sleep 2
set -x

groupadd controlm 2>/dev/null

useradd -g controlm -d ${DIR_WRK} -c "Agent for ControlM 8" -s /bin/csh ag800
RC_USR=$?

	if [ ${RC_USR} -ne 0 ]
	then
		[ ${RC_USR} -eq 9 ] && echo "ERRO - Usuario ag800 esta logado."
		exit 1
	fi

#Seta senha do usuario ag800
echo "123mudar" | passwd --stdin ag800

#Cria pasta de trabalho.
mkdir -p ${DIR_WRK}

	if [ -f "${INST_PKG}" ] 
	then
		cp -f ${INST_PKG} ${DIR_WRK} 
	else
		echo "ERRO - Eh necessario informar o pacote de instalacao."
		exit 1
	fi
		
cd ${DIR_WRK} && tar zxvf ${INST_PKG}
[ $? -ne 0 ] && exit 1
chmod -R 775 ${DIR_WRK}

chown -R ag800:controlm ${DIR_WRK}

cd ${DIR_WRK} || exit 1

set +x
echo "

	+------------------------------------------------------------
	|  
	|  Criando arquivo XML para Instalacao. 
	|  ${INST_XML}
	|
	+------------------------------------------------------------\n"
	
sleep 2
set -x

echo "<AutomatedInstallation langpack=\"eng\">
    <target.product>Control-M/Agent 8.0.00</target.product>
    <agent.parameters>
        <entry key=\"field.Authorized.Controlm.Server.Host\" value=\"net001uatlnx164\"/>
        <entry key=\"field.Agent.To.Server.Port.Number\" value=\"7105\"/>
        <entry key=\"field.Server.To.Agent.Port.Number\" value=\"7106\"/>
        <entry key=\"field.Primary.Controlm.Server.Host\" value=\"net001uatlnx164\"/>
        <entry key=\"INSTALL_PATH\" value=\"${DIR_WRK}\"/>
    </agent.parameters>
</AutomatedInstallation>" >${INST_XML}

[ -f "${INST_XML}" ] || exit 1

set +x
echo "
	+------------------------------------------------------------
	|  
	|  Inciando instalacao. Parametro = install_ag.xml
	|
	+------------------------------------------------------------\n"
	
sleep 2
set -x

${DIR_WRK}/setup.sh -silent ${INST_XML}
if [ $? -ne 0 ]
then
set +x
echo "
	+------------------------------------------------------------
	|  
	|  ERRO - Ocorreu um erro na instalacao.
	|	Favor verificar o LOG.	
        | 
	+------------------------------------------------------------\n"
	exit 1

else
set +x
echo "
	+------------------------------------------------------------
	|  
	|  Instalacao do Agent 800 concluida.
	|  Favor enviar este resultado a equipe de PCP.
	|
	|  Equipe de PCP, favor cadastrar o Agent:
	|  HOSTNAME = $(hostname)
	|  SERVER AUTORIZADO = net001uatlnx164
	|  PORT S2A = 7106
	|  PORT A2S = 7105
	|
	|  Para iniciar o Agent favor executar o seguinte comando:
	|  ${DIR_WRK}/ctm/scripts/start-ag -u ag800 -p ALL
	|
        |                                                Obrigado
	+------------------------------------------------------------\n"

rm -f ${DIR_WRK}/${INST_PKG}

${DIR_WRK}/ctm/scripts/rc.agent_user
[ $? -ne 0 ] && exit 1 || exit 0

fi
