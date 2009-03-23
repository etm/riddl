package org.riddl.generator;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;

import org.riddl.ns.description._1.Description;
import org.riddl.ns.description._1.Message;
import org.riddl.ns.description._1.Parameter;
import org.riddl.ns.description._1.Part;
import org.riddl.ns.description._1.Resource;
import org.riddl.ns.description._1.RiddlResource;

public class Riddl2Java 
{

	/**
	 * @param args
	 * @throws JAXBException 
	 */
	public static void main(String[] args) throws JAXBException 
	{
		File riddlDescription = new File(args[0]);
		File outputDirectory = new File(args[1]);
		String basePackage = args[2];
		
		String messagesPackage = basePackage + ".messages";
		String resourcesPackage = basePackage + ".resources";
		
		File messagesDirectory = new File(outputDirectory, messagesPackage.replace(".", File.separator));
		File resourcesDirectory = new File(outputDirectory, resourcesPackage.replace(".", File.separator));
		
		messagesDirectory.mkdirs();
		resourcesDirectory.mkdirs();
		
		JAXBContext deserializationContext = JAXBContext.newInstance(Description.class);
		
		Description description = (Description) deserializationContext.createUnmarshaller().unmarshal(riddlDescription);
		
		for(Message message : description.getMessage())
		{
			String messageClassName = createValidClassName(message.getName());
			StringBuilder messageClassContent = new StringBuilder();
			messageClassContent.append("// PREFACE \n");
			messageClassContent.append("package " + messagesPackage + ";\n");
			messageClassContent.append("public class " + messageClassName + "\n");
			messageClassContent.append("{\n");
			
			StringBuilder messageClassDeclarations = new StringBuilder();
			StringBuilder messageClassMethods = new StringBuilder();
			
			for(Parameter parameter : message.getParameter())
			{
				Field field = createFieldFromParameter(parameter);
				messageClassDeclarations.append(field.createJavaString());
			}
			
			for(Part part : message.getPart())
			{
				String handlerURI = part.getHandler();
				MessagePartContentStubGenerator messagePartContentStubGenerator = MessagePartContentStubGeneratorFactory.getInstance().getHandlerByURIString(handlerURI);
				messagePartContentStubGenerator.setMessageOutputDirectory(messagesDirectory);
				messagePartContentStubGenerator.setMessagesPackage(messagesPackage);
				messagePartContentStubGenerator.setPartContent(part.getAny());
				String partClassName = messagePartContentStubGenerator.generate();
				Field field = new Field();
				field.setName(makeFirstLetterLowercase(partClassName));
				field.setType(partClassName);
				field.setPrefixes("private");
				messageClassDeclarations.append(field.createJavaString());
			}
			
			messageClassContent.append(messageClassDeclarations);
			messageClassContent.append("}\n");
			
			File messageClassFile = new File(messagesDirectory, messageClassName + ".java");
			try {
				FileWriter fileWriter = new FileWriter(messageClassFile);
				fileWriter.write(messageClassContent.toString());
				fileWriter.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			
		}
		
		
		RiddlResource rootResource = description.getResource();
		List<Resource> resources = rootResource.getResource();
		generateResourceStubs(resourcesPackage, resourcesDirectory, "", resources);
	}

	private static void generateResourceStubs(String resourcesPackage,
			File resourcesDirectory, String resourceParentName, List<Resource> resources) 
	{
		for(Resource resource : resources)
		{
			String resourceClassName = "";
			if(resource.getRelative() == null)
			{
				resourceClassName = resourceParentName + createValidClassName(resource.getRelative());
			}
			else
			{
				resourceClassName = resourceParentName + "Item";
			}
			generateResourceStubs(resourcesPackage, resourcesDirectory, resourceParentName, resource.getResource());

			StringBuilder resourceClassContent = new StringBuilder();
			resourceClassContent.append("// PREFACE \n");
			resourceClassContent.append("package " + resourcesPackage + ";\n");
			resourceClassContent.append("public class " + resourceClassName + "\n");
			resourceClassContent.append("{\n");
			
			StringBuilder resourceClassDeclarations = new StringBuilder();
			
			
			resourceClassContent.append("}\n");

			File resourceClassFile = new File(resourcesDirectory, resourceClassName + ".java");
			try {
				FileWriter fileWriter = new FileWriter(resourceClassFile);
				fileWriter.write(resourceClassContent.toString());
				fileWriter.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

			
		}
	}

	private static Field createFieldFromParameter(Parameter parameter) {
		Field field = new Field();
		field.setName(parameter.getName());
		field.setType(makeFirstLetterUppercase(parameter.getType()));
		field.setPrefixes("private");
		if(parameter.getFixedValue() != null)
		{
			field.getPrefixes().add("static");
			field.getPrefixes().add("final");
		}
		if(parameter.getFixedValue() != null)
		{
			field.setInitializationValue(parameter.getFixedValue());
			if(field.getType().equals("String"))
			{
				field.setQuoteInitializationValue(true);
			}
		}
		return field;
	}
	
	private static String createValidClassName(String classNameCandidate)
	{
		StringBuilder classNameBuilder = new StringBuilder();
		int position = 0;
		
		String[] classNameChunks = classNameCandidate.split("-");
		for(String classNameChunk : classNameChunks)
		{
			classNameBuilder.append(makeFirstLetterUppercase(classNameChunk));
		}
			
		
		return classNameBuilder.toString();
	}

	private static String makeFirstLetterUppercase(String originalString) {
		return originalString.substring(0, 1).toUpperCase() + originalString.substring(1);
	}

	private static String makeFirstLetterLowercase(String originalString) {
		return originalString.substring(0, 1).toLowerCase() + originalString.substring(1);
	}
	

	

	

}
