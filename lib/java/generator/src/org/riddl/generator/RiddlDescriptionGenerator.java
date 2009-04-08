package org.riddl.generator;

import java.io.File;
import java.math.BigInteger;
import java.util.List;

import org.riddl.description.Description;
import org.riddl.description.Message;
import org.riddl.description.Parameter;
import org.riddl.description.Part;
import org.riddl.description.Resource;
import org.riddl.description.RiddlResource;

import com.sun.codemodel.JClassAlreadyExistsException;
import com.sun.codemodel.JCodeModel;
import com.sun.codemodel.JDefinedClass;
import com.sun.codemodel.JExpr;
import com.sun.codemodel.JExpression;
import com.sun.codemodel.JFieldVar;
import com.sun.codemodel.JMod;
import com.sun.codemodel.JPackage;
import com.sun.codemodel.JType;

public class RiddlDescriptionGenerator 
{

	private static final MessagePartContentStubGeneratorFactory messagePartContentStubGeneratorFactory = MessagePartContentStubGeneratorFactory.getInstance();
	private JPackage messagesPackage;
	private JPackage resourcePackage;
	private Description description;
	private JCodeModel jCodeModel = new JCodeModel();
	private File baseDirectory;
	
	
	
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
			
			String messageClassName = createValidClassName(message.getName());

			JDefinedClass messageClass = messagesPackage._class(messageClassName);
			JPackage thisMessagePackage = jCodeModel._package(messagesPackage.name() + "." + makeFirstLetterLowercase(messageClassName));
			
			
			for(Parameter parameter : message.getParameter())
			{
				JFieldVar field = messageClass.field(getFieldModifiersFromParameter(parameter), getOrCreateType(parameter.getType(), jCodeModel), parameter.getName());
				if(parameter.getFixedValue() != null)
				{
					field.init(createExpression(field.type(), parameter.getFixedValue()));
				}
				
			}
			
			int partNumber = 0;
			for(Part part : message.getPart())
			{
				try {
					
					JPackage partPackage = jCodeModel._package(thisMessagePackage.name() + ".part" + partNumber);

					String handlerURI = part.getHandler();
					
					MessagePartContentStubGenerator messagePartContentStubGenerator = messagePartContentStubGeneratorFactory
							.getHandlerByURIString(handlerURI);
					messagePartContentStubGenerator.setCodeModel(jCodeModel);
					messagePartContentStubGenerator
							.setPartPackage(partPackage);
					messagePartContentStubGenerator.setPartContent(part
							.getAny());
					messagePartContentStubGenerator.setBaseDirectory(baseDirectory);
					System.out.println("Creating stubs for part #" + partNumber + " of message " + message.getName() + " with handler " + handlerURI);
					JType partType = messagePartContentStubGenerator.generate();
					messageClass.field(JMod.PRIVATE, partType,
							makeFirstLetterLowercase(partType.name()));
					partNumber++;
				} catch (Exception e) {
					System.out.println(e);
				}
			}
			
			
		}
		
		
		RiddlResource rootResource = description.getResource();
		List<Resource> resources = rootResource.getResource();
		generateResourceStubs(resourcePackage, "", resources);
	}
	private JExpression createExpression(JType type, String fixedValue) 
	{
		
		JExpression expression;
		if("String".equalsIgnoreCase(type.name()))
		{
			expression = JExpr.lit(fixedValue);
		}
		else
		{
			expression = JExpr.direct(fixedValue);
		}
		return expression;
	}
	public static JType getOrCreateType(String type, JCodeModel codeModel) throws ClassNotFoundException 
	{
		JType result = codeModel.NULL;
		if("String".equalsIgnoreCase(type))
		{
			result = codeModel.ref(String.class);
		} 
		else if("int".equalsIgnoreCase(type))
		{
			result = codeModel.INT;
		}
		else if("integer".equalsIgnoreCase(type))
		{
			result = codeModel._ref(BigInteger.class);
		}
		
		
		return result;
	}
	
	private void generateResourceStubs(JPackage recourcePackage, String resourceParentName, List<Resource> resources) 
	{
		for(Resource resource : resources)
		{
			String resourceClassName = "";
			if(resource.getRelative() != null)
			{
				resourceClassName = resourceParentName + createValidClassName(resource.getRelative());
			}
			else
			{
				resourceClassName = resourceParentName + "Item";
			}
			generateResourceStubs(resourcePackage, resourceParentName, resource.getResource());

		}
	}

	
	private String createValidClassName(String classNameCandidate)
	{
		StringBuilder classNameBuilder = new StringBuilder();
		
		String[] classNameChunks = classNameCandidate.split("-");
		for(String classNameChunk : classNameChunks)
		{
			classNameBuilder.append(makeFirstLetterUppercase(classNameChunk));
		}
			
		
		return classNameBuilder.toString();
	}

	private String makeFirstLetterUppercase(String originalString) {
		return originalString.substring(0, 1).toUpperCase() + originalString.substring(1);
	}

	private String makeFirstLetterLowercase(String originalString) {
		return originalString.substring(0, 1).toLowerCase() + originalString.substring(1);
	}
	private int getFieldModifiersFromParameter(Parameter parameter) 
	{
		
		int modifier = JMod.PRIVATE;
		if(parameter.getFixedValue() != null)
		{
			modifier |= JMod.FINAL | JMod.STATIC;
		}

		return modifier;
	}


}
