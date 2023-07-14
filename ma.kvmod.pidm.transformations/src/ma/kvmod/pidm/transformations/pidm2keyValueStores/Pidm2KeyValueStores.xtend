package ma.kvmod.pidm.transformations.pidm2keyValueStores

import keyValueDataModel.Property
import keyValueDataModel.keyValueDataModel
import keyValueDataModel.keyValueDataModelFactory
import keyValueDataModel.keyValueDataModelPackage
import keyValueDataModel.PrimitiveType
import keyValueDataModel.SimpleType
import ma.kvmod.pidm.lang.pidmLang.AndConjunction
import ma.kvmod.pidm.lang.pidmLang.Attribute
import ma.kvmod.pidm.lang.pidmLang.AttributeSelection
import ma.kvmod.pidm.lang.pidmLang.BooleanExpression
import ma.kvmod.pidm.lang.pidmLang.Comparison
import ma.kvmod.pidm.lang.pidmLang.Entity
import ma.kvmod.pidm.lang.pidmLang.Equality
import ma.kvmod.pidm.lang.pidmLang.PidmLangPackage
import ma.kvmod.pidm.lang.pidmLang.LessThan
import ma.kvmod.pidm.lang.pidmLang.LessThanOrEqual
import ma.kvmod.pidm.lang.pidmLang.Model
import ma.kvmod.pidm.lang.pidmLang.MoreThan
import ma.kvmod.pidm.lang.pidmLang.MoreThanOrEqual
import ma.kvmod.pidm.lang.pidmLang.OrConjunction
import ma.kvmod.pidm.lang.pidmLang.Query
import ma.kvmod.pidm.lang.pidmLang.Reference
import ma.kvmod.pidm.transformations.common.Tree
import java.io.File
import java.io.IOException
import java.util.ArrayList
import java.util.Collections
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl

class Pidm2KeyValue {

  // Test the transformation below
  def static void main(String[] args) {
    val example = "airFlight"
    println("PiDM to key value logical model")
    println(String.format("Example: %s", example))
    val totalStart = System.currentTimeMillis()
    // Prepare the xmi resource persistence
    val Resource.Factory.Registry reg = Resource.Factory.Registry.INSTANCE
    val m = reg.extensionToFactoryMap
    m.put("model", new XMIResourceFactoryImpl())
    // Initialize models
    PidmLangPackage.eINSTANCE.eClass
    keyValueDataModelPackage.eINSTANCE.eClass
    // Load the PIDM model
    val input = new File(
      String.format("../ma.kvmod.pidm.examples/%s.model",
                    example))
    val resSet = new ResourceSetImpl()
    val inputResource = resSet.getResource(URI.createURI(input.canonicalPath),
      true
    )
    val pidm = inputResource.contents.get(0) as Model
    // Transform it
    val start = System.currentTimeMillis()
    val keyValueDM = transformPidm2keyValue(pidm)
    val end = System.currentTimeMillis()
    // Save the key value data model
    val output = new File(
      String.format("../ma.kvmod.pidm.examples/collection/%sC.model",
                    example))
    val outputResource = resSet.createResource(
      URI.createURI(output.canonicalPath)
    )
    outputResource.getContents().add(keyValueDM)
    try {
      outputResource.save(Collections.EMPTY_MAP)
    } catch (IOException e) {
      e.printStackTrace()
    }
    val totalEnd = System.currentTimeMillis()
    println("Transformation finished")
    println(String.format("Transformation time: %d ms", end - start))
    println(String.format("Total time (read/write files and models): %d ms",
        totalEnd - totalStart))
  }

  def static keyValueDataModel transformPidm2keyValueStores(Model pidm) {
    val CFactory = CDataModelFactory.eINSTANCE
    val CDataModel cfModel = cFactory.createCDataModel()
    // datasets generation
    for (query : pidm.queries) {
      val dataset = generateDataset(query, cFactory)
      cModel.datasets.add(dataset)
    }
    return cModel
  }

  def private static generateDataset(Query query,
      CDataModelFactory cFactory) {
    val orderingAttributes = new ArrayList<Attribute>
    orderingAttributes.addAll(
      getInequalities(query.condition).map[ineq | ineq.selection.attribute])
    val queryOrderingAttributes = query.orderingAttributes
        .map[ordattr | ordattr.attribute]
    if (compatibleOrdering(orderingAttributes, queryOrderingAttributes)) {
      for (attr : queryOrderingAttributes) {
        if (!orderingAttributes.contains(attr)) {
          orderingAttributes.add(attr)
        }
      }
    }
    val Map<Attribute, Property> attr2property = new HashMap<Attribute, Property>
    val dataset = cFactory.createDataset()
    dataset.name = query.name
    for (projection : query.projections) {
      val property = cFactory.createProperty
      property.name = getName(projection)
      property.type = getType(cFactory, projection.attribute)
      dataset.properties.add(property)
      attr2property.put(projection.attribute, property)
    }
    val projectionAttributes = query.projections.map[p | p.attribute]
    }
    for (orderingAttribute : orderingAttributes) {
      var Property property = null
      if (projectionAttributes.contains(orderingAttribute)) {
        property = attr2property.get(orderingAttribute)
      } else {
        // create new property that was not present in the projection
        property = cFactory.createProperty
        property.name = orderingAttribute.name
        property.type = getType(cFactory, orderingAttribute)
        dataset.properties.add(property)
      }

    }
    return dataset
  }


/**
   * Get all unique attributes declared in a given entity
   */
  def private static List<Attribute> getUniqueAttributes(Entity entity) {
    return entity.features
                 .filter(f | f instanceof Attribute)
                 .map(f | (f as Attribute))
                 .filter[attr | attr.isUnique()]
                 .toList()
  }

  /**
   * Get all unique attributes of the entity and of those entities that are
   * reachable by traversing one or more 1-bounded references of the given
   * access tree
   */
  def private static List<Attribute> getAllUniqueAttributes(Entity entity,
      Tree<Reference> tree) {
    val uniqueAttrs = entity.getUniqueAttributes()
    for (child : tree.children) {
      if (child.data.cardinality.equals("1")) {
        uniqueAttrs.addAll(child.data.entity.getAllUniqueAttributes(child))
      }
    }
    return uniqueAttrs
  }

  /**
   * Check if attrs contains at least one attribute present in otherAttrs
   */
  def private static boolean containsOne(List<Attribute> attrs,
      List<Attribute> otherAttrs) {
    for (otherAttr : otherAttrs) {
      if (attrs.contains(otherAttr)) {
        return true
      }
    }
    return false
  }

  def private static Tree<Reference> createAccessTree(Query query) {
    // root element of the tree has no reference
    val tree = new Tree<Reference> (null)
    for (inclusion : query.inclusions) {
      // populate the tree with all the concatenated references
      var auxTree = tree
      for (ref : inclusion.refs) {
        val child = auxTree.add(ref)
        auxTree = child // we keep adding children down the rabbit hole
      }
    }
    return tree
  }

  def private static compatibleOrdering(
      List<Attribute> inequalitiesOrdering,
      List<Attribute> queryOrdering) {
    val inequalityOrderingIterator = inequalitiesOrdering.iterator()
    val queryOrderingIterator = queryOrdering.iterator()

    while (inequalityOrderingIterator.hasNext() &&
        queryOrderingIterator.hasNext()) {
      val inequalityOrderingAttr = inequalityOrderingIterator.next()
      val queryOrderingAttr = queryOrderingIterator.next()
      if (!inequalityOrderingAttr.equals(queryOrderingAttr)){
        return false // incompatible ordering detected at this point
      }
    }
    // two possibilities: (1) the inequality ordering iterator is empty, and thus
    //   orderings are compatible; (2) not empty, not compatible
    if (!inequalityOrderingIterator.hasNext()) {
      return true
    } else {
      return false
    }
  }


  def private static List<Comparison> getInequalities(BooleanExpression expression) {
    val inequalities = new ArrayList<Comparison>
    if (expression instanceof AndConjunction) {
      inequalities.addAll(getInequalities((expression as AndConjunction).left))
      inequalities.addAll(getInequalities((expression as AndConjunction).right))
    } else if (expression instanceof OrConjunction) {
      inequalities.addAll(getInequalities((expression as OrConjunction).left))
      inequalities.addAll(getInequalities((expression as OrConjunction).right))
    } else if (expression instanceof MoreThan ||
               expression instanceof MoreThanOrEqual ||
               expression instanceof LessThan ||
               expression instanceof LessThanOrEqual) {
      inequalities.add(expression as Comparison)
    }
    return inequalities
  }

  def private static List<Equality> getEqualities(BooleanExpression expression) {
    val equalities = new ArrayList<Equality>
    if (expression instanceof AndConjunction) {
      equalities.addAll(getEqualities((expression as AndConjunction).left))
      equalities.addAll(getEqualities((expression as AndConjunction).right))
    } else if (expression instanceof OrConjunction) {
      equalities.addAll(getEqualities((expression as OrConjunction).left))
      equalities.addAll(getEqualities((expression as OrConjunction).right))
    } else if (expression instanceof Equality) {
      equalities.add(expression as Equality)
    }
    return equalities
  }

  def private static getType(KeyValueDataModelFactory cFactory,
      Attribute attribute) {
    val SimpleType st = cFactory.createSimpleType
    switch (attribute.type) {
      case ID: {
        st.type = PrimitiveType.ID
      }
      case BOOLEAN: {
        st.type = PrimitiveType.BOOLEAN
      }
      case NUMBER: {
        st.type = PrimitiveType.FLOAT
      }
      case DATE: {
        st.type = PrimitiveType.DATE
      }
      default: {
        st.type = PrimitiveType.TEXT
      }
    }
    return st
  }

  def private static getName(AttributeSelection selection) {
    if (selection.alias !== null) {
      return selection.alias
    }
    return selection.attribute.name
  }

}
