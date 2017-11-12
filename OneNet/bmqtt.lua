require"misc"
require"mqtt"
require"common"
require"bgps"
module(...,package.seeall)

local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len
--����ʱ���Լ��ķ�����
local PROT,ADDR,PORT = "TCP","183.230.40.39",6002   --onenet mqtt broker������ip
local mqttclient


--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
  _G.print("bmqtt",...)
end

local qos0cnt,qos1cnt = 1,1



--[[
��������msgPack
���ܣ��Լ������͵�msg���д��
��������
����ֵ����
]]
local function msgPack()
  print("pack test")
  print("bgps.lng bgps.lat",bgps.returnBlng(),bgps.returnBlat())
  local torigin = 
  {
    datastreams = 
    {{
      id = "gps",
      datapoints = 
      {{
        at = "",
        value = 
        {
          lon = bgps.returnBlng(),
          lat = bgps.returnBlat(),
          ele = "100"
        }
      }}
    }}
  }
  local msg = json.encode(torigin)
  print("json data",msg)
--  local msg = "{\"datastreams\":[{\"id\":\"temperature\",\"datapoints\":[{\"at\":\"\",\"value\":40}]}]}"
--  local msg = "{\"datastreams\":[{\"id\":\"gps\",\"datapoints\":[{\"at\":\"\",\"value\":{\"lon\":106.2476033,\"lat\":29.2824583,\"ele\":100}}]}]}"
  local len = msg.len(msg)
  buf = pack.pack("bbbA", 0x01,0x00,len,msg)
  print("pack buf",buf)
end


--[[
��������pubGpsMsg
����  ������GPS���ݵ�������
����  ����
����ֵ����
]]
local function pubGpsMsg()
  msgPack()
  mqttclient:publish("$dp",buf,0)
end



--[[
��������subackcb
����  ��MQTT SUBSCRIBE֮���յ�SUBACK�Ļص�����
����  ��
    usertag������mqttclient:subscribeʱ�����usertag
    result��true��ʾ���ĳɹ���false����nil��ʾʧ��
����ֵ����
]]
local function subackcb(usertag,result)
  print("subackcb",usertag,result)
end

--[[
��������rcvmessage
����  ���յ�PUBLISH��Ϣʱ�Ļص�����
����  ��
    topic����Ϣ���⣨gb2312���룩
    payload����Ϣ���أ�ԭʼ���룬�յ���payload��ʲô���ݣ�����ʲô���ݣ�û�����κα���ת����
    qos����Ϣ�����ȼ�
����ֵ����
]]
local function rcvmessagecb(topic,payload,qos)
  print("rcvmessagecb",topic,payload,qos)
end

--[[
��������discb
����  ��MQTT���ӶϿ���Ļص�
����  ����    
����ֵ����
]]
local function discb()
  print("discb")
  --20������½���MQTT����
  sys.timer_start(connect,20000)
end

--[[
��������disconnect
����  ���Ͽ�MQTT����
����  ����    
����ֵ����
]]
local function disconnect()
  mqttclient:disconnect(discb)
end

--[[
��������connectedcb
����  ��MQTT CONNECT�ɹ��ص�����
����  ����    
����ֵ����
]]
local function connectedcb()
  print("connectedcb")
  --��������
  mqttclient:subscribe({{topic="/event0",qos=0}, {topic="/����event1",qos=1}}, subackcb, "subscribetest")
  --ע���¼��Ļص�������MESSAGE�¼���ʾ�յ���PUBLISH��Ϣ
  mqttclient:regevtcb({MESSAGE=rcvmessagecb})
  --����һ��qosΪ0����Ϣ
--  pubqos0test()
  --����һ��qosΪ1����Ϣ
--  pubqos1test()
  --20��������Ͽ�MQTT����
  sys.timer_loop_start(pubGpsMsg,15000)
end

--[[
��������connecterrcb
����  ��MQTT CONNECTʧ�ܻص�����
����  ��
    r��ʧ��ԭ��ֵ
      1��Connection Refused: unacceptable protocol version
      2��Connection Refused: identifier rejected
      3��Connection Refused: server unavailable
      4��Connection Refused: bad user name or password
      5��Connection Refused: not authorized
����ֵ����
]]
local function connecterrcb(r)
  print("connecterrcb",r)
end

--[[
��������sckerrcb
����  ��SOCKET�쳣�ص�������ע�⣺�˴��ǻָ��쳣��һ�ַ�ʽ<�������ģʽ������Ӻ��˳�����ģʽ>������޷������Լ������󣬿��Լ������쳣����
����  ��
    r��string���ͣ�ʧ��ԭ��ֵ
      CONNECT��mqtt�ڲ���socketһֱ����ʧ�ܣ����ٳ����Զ�����
      SVRNODATA��mqtt�ڲ���3��KEEP ALIVEʱ��+����ӣ��ն˺ͷ�����û���κ�����ͨ�ţ�����Ϊ����ͨ���쳣
����ֵ����
]]
local function sckerrcb(r)
  print("sckerrcb",r)
  misc.setflymode(true)
  sys.timer_start(misc.setflymode,30000,false)
end

function connect()
  --����mqtt������
  --mqtt lib�У����socket�����쳣��Ĭ�ϻ��Զ��������
  --ע��sckerrcb�������������ע�͵���sckerrcb����mqtt lib��socket�����쳣ʱ�������Զ�������������ǵ���sckerrcb����
  mqttclient:connect("11171119",120,"93855","123456",connectedcb,connecterrcb--[[,sckerrcb]])
end

local function statustest()
  print("statustest",mqttclient:getstatus())
end

--[[
��������imeirdy
����  ��IMEI��ȡ�ɹ����ɹ��󣬲�ȥ����mqtt client�����ӷ���������Ϊ�õ���IMEI��
����  ����    
����ֵ����
]]
local function imeirdy()
  --����һ��mqtt client��Ĭ��ʹ�õ�MQTTЭ��汾��3.1�����Ҫʹ��3.1.1���������ע��--[[,"3.1.1"]]����
  mqttclient = mqtt.create(PROT,ADDR,PORT,"3.1.1")
  --������������,�������Ҫ��������һ�д��룬���Ҹ����Լ����������will����
  --mqttclient:configwill(1,0,0,"/willtopic","will payload")
  --����clean session��־���������Ҫ��������һ�д��룬���Ҹ����Լ�����������cleansession����������ã�Ĭ��Ϊ1
  --mqttclient:setcleansession(0)
  --��ѯclient״̬����
  --sys.timer_loop_start(statustest,1000)
  connect()
end

local procer =
{
  IMEI_READY = imeirdy,
}
--ע����Ϣ�Ĵ�����
sys.regapp(procer)
