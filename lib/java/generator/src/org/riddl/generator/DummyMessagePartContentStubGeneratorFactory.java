package org.riddl.generator;

public class DummyMessagePartContentStubGeneratorFactory extends
		MessagePartContentStubGeneratorFactory 
{
	private static MessagePartContentStubGeneratorFactory instance = new DummyMessagePartContentStubGeneratorFactory();
	private DummyMessagePartContentStubGeneratorFactory() {
		super();
	}
	
	public static MessagePartContentStubGeneratorFactory getInstance()
	{
		return instance;
	}
	
	
	@Override
	public MessagePartContentStubGenerator getHandlerByURIString(
			String handlerURI) {
		return new DefaultMessagePartContentStubGenerator();
	}
	
	@Override
	public MessagePartContentStubGenerator getDefaultHandlerForMimeType(
			String mimeType) {
		return new DefaultMessagePartContentStubGenerator();
	}

}
