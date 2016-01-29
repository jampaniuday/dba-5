select COMPONENT_NAME, FND_SVC_COMPONENT.Get_Component_Status(COMPONENT_NAME) COMPONENT_STATUS
from apps.FND_SVC_COMPONENTS
where component_type like '%MAILER%';
