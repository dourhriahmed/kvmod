/*
 * generated by Xtext 2.13.0
 */
package ma.kvmod.pidm.lang


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class PidmLangStandaloneSetup extends PidmLangStandaloneSetupGenerated {

	def static void doSetup() {
		new PidmLangStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}