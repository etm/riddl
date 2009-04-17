package org.riddl.generator;

import java.io.File;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.ws.rs.Path;
import javax.ws.rs.PathParam;

import org.riddl.description.Description;
import org.riddl.description.Message;
import org.riddl.description.Method;
import org.riddl.description.Parameter;
import org.riddl.description.Part;
import org.riddl.description.Resource;
import org.riddl.description.RiddlResource;

import com.sun.codemodel.JAnnotationUse;
import com.sun.codemodel.JArray;
import com.sun.codemodel.JAssignmentTarget;
import com.sun.codemodel.JClass;
import com.sun.codemodel.JClassAlreadyExistsException;
import com.sun.codemodel.JCodeModel;
import com.sun.codemodel.JDefinedClass;
import com.sun.codemodel.JExpr;
import com.sun.codemodel.JExpression;
import com.sun.codemodel.JInvocation;
import com.sun.codemodel.JMethod;
import com.sun.codemodel.JMod;
import com.sun.codemodel.JPackage;
import com.sun.codemodel.JType;
import com.sun.codemodel.JVar;
import com.sun.xml.bind.api.impl.NameConverter;

public class RiddlDescriptionGenerator 
{

	private static final NameConverter NAME_CONVERTER = NameConverter.standard;
	private static final MessagePartContentStubGeneratorFactory messagePartContentStubGeneratorFactory = MessagePartContentStubGeneratorFactory.getInstance();
	private JPackage messagesPackage;
	private JPackage resourcePackage;
	private Description description;
	private JCodeModel jCodeModel = new JCodeModel();
	private File baseDirectory;
	private Map<String, JClass> messageNameToTypeMap = new HashMap<String, JClass>();
	private JClass abstractMessageClass = jCodeModel.ref(org.riddl.runtime.Message.class);
	private JClass arrayOfClasses = jCodeModel._ref(Class.class).array();
	private Map<String, JType> schema2JavaTypeMap = XSDSimpleTypeToJavaTypeMapFactory.create(jCodeModel); 
	
	
	public File getBaseDirectory() {
		return baseDirectory;
	}
	public void setBaseDirectory(File baseDirectory) {
		this.baseDirectory = baseDirectory;
	}
	public JCodeModel getJCodeModel() {
		return jCodeModel;
	}
	public void setJCodeModel(JCodeModel codeModel) {
		jCodeModel = codeModel;
	}
	public JPackage getMessagesPackage() {
		return messagesPackage;
	}
	public void setMessagesPackage(JPackage messagesPackage) {
		this.messagesPackage = messagesPackage;
	}
	public JPackage getResourcePackage() {
		return resourcePackage;
	}
	public void setResourcePackage(JPackage resourcePackage) {
		this.resourcePackage = resourcePackage;
	}
	public Description getDescription() {
		return description;
	}
	public void setDescription(Description description) {
		this.description = description;
	}
	public void generateRiddleDecriptionStubs() throws JClassAlreadyExistsException, ClassNotFoundException 
	{
		for(Message message : description.getMessage())
		{
			String messageClassName = NAME_CONVERTER.toClassName(message.getName());
			JPackage thisMessagePackage = jCodeModel._package(messagesPackage.name() + "." + NAME_CONVERTER.toPackageName(messageClassName));
			

			JDefinedClass messageClass = messagesPackage._class(messageClassName);
			messageClass._extends(abstractMessageClass);
			
			JMethod defaultConstructor = messageClass.constructor(JMod.PUBLIC);
			defaultConstructor.body().assign(JExpr.refthis("parameters"), JExpr.newArray(jCodeModel.ref(org.riddl.runtime.Parameter.class), message.getParameter().size()));
			defaultConstructor.body().assign(JExpr.refthis("parts"), JExpr.newArray(jCodeModel.ref(org.riddl.runtime.Part.class), message.getPart().size()));
			
			
			
			int parameterNumber = 0;
			for(Parameter parameter : message.getParameter())
			{
				JType parameterType = schema2JavaTypeMap.get(parameter.getType());
				
				JExpression parameterArrayElement = JExpr.refthis("parameters").component(JExpr.lit(parameterNumber));
				
				JMethod parameterGetter = messageClass.method(JMod.PUBLIC, parameterType, "get" + NAME_CONVERTER.toPropertyName(parameter.getName()));
				parameterGetter.body()._return(JExpr.cast(parameterType, parameterArrayElement.invoke("getValue")));
				
				JMethod parameterSetter = messageClass.method(JMod.PUBLIC, jCodeModel.VOID, "set" + NAME_CONVERTER.toPropertyName(parameter.getName()));
				parameterSetter.param(parameterType, NAME_CONVERTER.toVariableName(parameter.getName()));
				JInvocation newParameter = JExpr._new(jCodeModel._ref(org.riddl.runtime.Parameter.class)).arg(parameter.getName()).arg(parameter.getType()).arg(JExpr.ref(NAME_CONVERTER.toVariableName(parameter.getName())));
				parameterSetter.body().assign((JAssignmentTarget) parameterArrayElement, newParameter);
				
				parameterNumber++;
			}
			
			int partNumber = 0;
			for(Part part : message.getPart())
			{
				try {
					
					JPackage partPackage = jCodeModel._package(thisMessagePackage.name() + "." + NAME_CONVERTER.toPackageName(part.getName()));

					String handlerURI = part.getHandler();
					
					MessagePartContentStubGenerator messagePartContentStubGenerator = messagePartContentStubGeneratorFactory
							.getHandlerByURIString(handlerURI);
					messagePartContentStubGenerator.setCodeModel(jCodeModel);
					messagePartContentStubGenerator
							.setPartPackage(partPackage);
					messagePartContentStubGenerator.setPartContent(part
							.getAny());
					messagePartContentStubGenerator.setBaseDirectory(baseDirectory);
					System.out.println("Creating stubs for part <" + part.getName() + "> of message " + message.getName() + " with handler " + handlerURI);

					
					JType partType = messagePartContentStubGenerator.generate();
					
					JExpression partArrayElement = JExpr.refthis("parts").component(JExpr.lit(partNumber));
					
					JMethod partGetter = messageClass.method(JMod.PUBLIC, partType, "get" + NAME_CONVERTER.toPropertyName(part.getName()));
					partGetter.body()._return(JExpr.cast(partType, partArrayElement.invoke("getValue")));
					
					JMethod partSetter = messageClass.method(JMod.PUBLIC, jCodeModel.VOID, "set" + NAME_CONVERTER.toPropertyName(part.getName()));
					partSetter.param(partType, NAME_CONVERTER.toVariableName(part.getName()));
					JInvocation newPart = 
						JExpr
							._new(jCodeModel._ref(org.riddl.runtime.Part.class))
							.arg(part.getName())
							.arg(part.getType())
							.arg(part.getHandler())
							.arg(JExpr.ref(NAME_CONVERTER.toVariableName(part.getName())));
					
					partSetter.body().assign((JAssignmentTarget) partArrayElement, newPart);
					
					partNumber++;
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
			messageNameToTypeMap.put(message.getName(), messageClass);
			
		}
		
		
		RiddlResource rootResource = description.getResource();
		JDefinedClass rootClass = generateResourceClass(rootResource, resourcePackage, "Root");
		JAnnotationUse rootPathAnnotation = rootClass.annotate(Path.class);
		rootPathAnnotation.param("value", "/");
	}
	
	private String createResourceClassName(String parentName,
			Resource resource) 
	{
		if("Root".equals(parentName))
		{
			parentName = "";
		}
		String resourceClassName = "";
		if(resource.getRelative() != null)
		{
			resourceClassName = parentName + NAME_CONVERTER.toClassName(resource.getRelative());
		}
		else
		{
			resourceClassName = parentName + "Item";
		}
		return resourceClassName;
	}
	
	
	private JDefinedClass generateResourceClass(RiddlResource resource, JPackage resourcePackage, String resourceClassName) throws JClassAlreadyExistsException
	{
		
		JDefinedClass resourceClass = resourcePackage._class(JMod.PUBLIC | JMod.ABSTRACT, resourceClassName);
		resourceClass._extends(org.riddl.runtime.Resource.class);
		
		JArray getRequestClasses = JExpr.newArray(jCodeModel.ref(Class.class));
		
		for(Resource childResource : resource.getResource())
		{
			JClass childResourceClass = generateResourceClass(childResource, resourcePackage, createResourceClassName(resourceClassName, childResource));
			JMethod childGetter = resourceClass.method(JMod.PUBLIC | JMod.ABSTRACT, childResourceClass, "get" + childResourceClass.name());
			String pathValue = "";
			if(childResource.getRelative() != null)
			{
				pathValue = childResource.getRelative();
			}
			else
			{
				pathValue = "{item}";
				JVar idParam = childGetter.param(String.class, "item");
				JAnnotationUse pathParamAnnotation = idParam.annotate(PathParam.class);
				pathParamAnnotation.param("value", "item");
			}
			JAnnotationUse pathAnnotation = childGetter.annotate(Path.class);
			pathAnnotation.param("value", pathValue);
		}
		
		createMethods(resourceClass, getRequestClasses, resource.getGet(), "Get");
		createMethods(resourceClass, getRequestClasses, resource.getPut(), "Put");
		createMethods(resourceClass, getRequestClasses, resource.getPost(), "Post");
		createMethods(resourceClass, getRequestClasses, resource.getDelete(), "Delete");
		
		return resourceClass;
	}
	private void createMethods(JDefinedClass resourceClass,
			JArray getRequestClasses, List<? extends Method> methods, String type) {
		for(Method method : methods)
		{
			JType outType = messageNameToTypeMap.get(method.getOut());
			if(outType == null)
			{
				outType = abstractMessageClass;
			}
			JMethod jMethod = resourceClass.method(JMod.PROTECTED | JMod.ABSTRACT, outType, NAME_CONVERTER.toVariableName(type));
			String inName = method.getIn();
			JClass inType = messageNameToTypeMap.get(inName);
			if(inType == null)
			{
				inType = abstractMessageClass;
				inName = "request";
			}
			else
			{
				getRequestClasses.add(inType.staticRef("class"));
			}
			jMethod.param(inType, NAME_CONVERTER.toVariableName(inName));
		}
		if(!methods.isEmpty())
		{
			JMethod getRequestMessagesMethod = resourceClass.method(JMod.PROTECTED, arrayOfClasses, "get" + type + "InputMessages");
			getRequestMessagesMethod.body()._return(getRequestClasses);
			getRequestMessagesMethod.annotate(Override.class);
		}
	}



}
