package org.riddl.generator;

import java.math.BigInteger;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import com.sun.codemodel.JCodeModel;
import com.sun.codemodel.JType;

public class XSDSimpleTypeToJavaTypeMapFactory
{
	public static Map<String, JType> create(JCodeModel codeModel)
	{
		HashMap<String, JType> map = new HashMap<String, JType>();
		map.put("string", codeModel.ref(String.class));
		map.put("integer", codeModel.ref(BigInteger.class));
		map.put("int", codeModel.INT);
		map.put("long", codeModel.LONG);
		map.put("short", codeModel.SHORT);
		map.put("decimal", codeModel.ref(java.math.BigDecimal.class));
		map.put("float", codeModel.FLOAT);
		map.put("double", codeModel.DOUBLE);
		map.put("boolean", codeModel.BOOLEAN);
		map.put("byte", codeModel.BYTE);
		map.put("QName", codeModel.ref(javax.xml.namespace.QName.class));
		map.put("dateTime", codeModel.ref(java.util.Calendar.class));
		map.put("base64Binary", codeModel.BYTE.array());
		map.put("hexBinary", codeModel.BYTE.array());
		map.put("unsignedInt", codeModel.LONG);
		map.put("unsignedShort", codeModel.INT);
		map.put("unsignedByt", codeModel.SHORT);
		map.put("time", codeModel.ref(java.util.Calendar.class));
		map.put("date", codeModel.ref(java.util.Calendar.class));
		map.put("anySimpleType", codeModel.ref(java.lang.String.class));
		return Collections.unmodifiableMap(map);
	}
	
	
}
