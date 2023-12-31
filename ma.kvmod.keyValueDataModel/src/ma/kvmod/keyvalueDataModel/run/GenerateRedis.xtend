package ma.kvmod.keyvalueDataModel.run

import java.io.File
import java.io.PrintWriter
import org.eclipse.emf.common.util.URI
import org.eclipse.epsilon.common.parse.problem.ParseProblem
import org.eclipse.epsilon.common.util.StringProperties
import org.eclipse.epsilon.egl.EglTemplateFactory
import org.eclipse.epsilon.egl.EglTemplateFactoryModuleAdapter
import org.eclipse.epsilon.emc.emf.EmfModel
import org.eclipse.epsilon.eol.models.IRelativePathResolver

class GenerateRedis {
  // Perform the code generation step
  def static void main(String[] args) {
    val example = "airFlight"
    println("Redis schema generation")
    println(String.format("Example: %s", example))
    val totalStart = System.currentTimeMillis()
    val resourcesFolder = 
"../ma.kvmod.pidm.examples/keyValueFamily"
    // Load the key value family data model
    val kvDataModel = new EmfModel()
    val properties = new StringProperties()
    properties.put(EmfModel.PROPERTY_NAME, "keyValueFamilyDataModel")
    properties.put(EmfModel.PROPERTY_FILE_BASED_METAMODEL_URI,
        URI.createURI(("model/keyValueFamilyDataModel.ecore").toString()))
    val inputFile = new File(
      String.format("%s/%sCF.model", resourcesFolder, example))
    properties.put(EmfModel.PROPERTY_MODEL_URI,
        URI.createURI(inputFile.canonicalPath))
    properties.put(EmfModel.PROPERTY_READONLOAD, true)
    properties.put(EmfModel.PROPERTY_STOREONDISPOSAL, false)
    cfDataModel.load(properties, null as IRelativePathResolver)
    // Prepare and execute the template
    val templateModule =
        new EglTemplateFactoryModuleAdapter(new EglTemplateFactory())
    templateModule.parse(
        new File("epsilon/redis/keyValueFamilyDataModel2redis.egl"))
    if (templateModule.getParseProblems().size() > 0) {
      System.err.println("Parse errors occured...");
      for (ParseProblem problem : templateModule.getParseProblems()) {
        System.err.println(problem.toString());
      }
      return;
    }
    templateModule.getContext().getModelRepository().addModel(kvDataModel)
    val start = System.currentTimeMillis()
    val result = templateModule.execute
    val end = System.currentTimeMillis()
    templateModule.getContext().getModelRepository().dispose()
    // Print the results to a file
    val outputFile = new File(String.format("%s/%s.cql", resourcesFolder, example))
    new File(outputFile.parent).mkdirs // create any missing folder in the path
    val out = new PrintWriter(outputFile.canonicalPath)
    out.println(result)
    out.close
    val totalEnd = System.currentTimeMillis()
    println("Generation finished")
    println(String.format("Transformation time: %d ms", end - start))
    println(String.format("Total time (read/write files and models): %d ms",
        totalEnd - totalStart))
  }
}