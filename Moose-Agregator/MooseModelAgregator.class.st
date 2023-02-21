Class {
	#name : #MooseModelAgregator,
	#superclass : #Object,
	#instVars : [
		'originModel',
		'agregatedModel'
	],
	#category : #'Moose-Agregator'
}

{ #category : #'as yet unclassified' }
MooseModelAgregator class >> agregate: aMooseModel [

	^self
		new
		originModel: aMooseModel;
		agregatedModel: (MooseModel named: aMooseModel name , 'Agregate')
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> addInvocations: invocations to: agClass [

	| agMeth |
"	1halt."
	agMeth := self getAgMethodFor: agClass.
	invocations do: [ :inv | 
		(inv sender parentType isStub not and: [inv sender parentType mooseName ~= agClass mooseName] ) ifTrue: [ "
			1halt."
			(self createAssociationFrom: inv)
				sender: (self getAgMethodFor: (self getExistingEntity:  inv sender parentType  from: self agregatedModel ));
				addCandidate: agMeth;
				signature: inv signature ] ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> addSubInheritances: subInheritances to: agClass [
	subInheritances do: [ :subI | 
		(self createAssociationFrom: subI ) superclass: agClass ; subclass: (self getExistingEntity: subI subclass from: self agregatedModel) ] 
	
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> agregateAClass: anOriginClass [

	| agClass invocations |
	agClass := self
		           getExistingEntity: anOriginClass 
		           from: self agregatedModel.
	anOriginClass subInheritances ifNotEmpty: [ 
		self addSubInheritances: anOriginClass subInheritances to: agClass ].
	invocations := anOriginClass queryIncoming: FamixTInvocation.
	invocations ifNotEmpty: [ 
		self addInvocations: invocations to: agClass
		 ]  
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> agregateAClass: anOriginClass in: aPackage [
	(self checkExistingEntity: anOriginClass in: aPackage) ifFalse: [ self createEntityFrom: anOriginClass ].
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> agregateAPackage: anOriginPackage [
	| pkg |
	pkg := self getExistingEntity: anOriginPackage from:  self agregatedModel.
	anOriginPackage classes do: [ :c | self agregateAClass: c  ]
]

{ #category : #accessing }
MooseModelAgregator >> agregatedModel [

	^ agregatedModel
]

{ #category : #accessing }
MooseModelAgregator >> agregatedModel: anObject [

	agregatedModel := anObject
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> checkExistingEntity: anOriginEntity in: anAggregateContainer [

	^ anAggregateContainer children anySatisfy: [ :e | e name = anOriginEntity name ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> computeSetterFrom: aGetter [
	^ (aGetter , ':') asSymbol
	
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createAPackage: anOriginPackage [
"self haltIf: [ anOriginPackage name = 'DataFrame' ] ."
	self createEntityFrom: anOriginPackage. 
	anOriginPackage classes do: [ :c | (self createEntityFrom: c)].
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createAgregatedMethodFor: agClass [
	| methodClass agMethod |
	methodClass := (agClass metamodel traits detect: [ :e | e name = 'TMethod' ]) classUsers anyOne implementingClass.
	agMethod := methodClass new name: 'agregatedMethod' ; mooseModel: self agregatedModel  .
	agClass addMethod: agMethod .
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createAssociationFrom: anAssociation [

	^ anAssociation class
		  new
		  mooseModel: agregatedModel
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createEntityFrom: anEntity [
"In this method, we first get the parentSelectors of the original entity. For each of these parents, we look for the corresponding entity in the new model. We create a new entity (in the new model with the same type of the original one). For this new entity we put its parents using the dictionary. The order is important because if we start by creating the entity, and if the class has the same name has the package, when we look for the entity in the new model, class and package have the same mooseName and it raises an error."
	| newEntity dict |
	dict := Dictionary new.
	anEntity parentSelectors do: [ :sel | 
		dict at: sel put: (self
				 getExistingEntity: (anEntity perform: sel)
				 from: self agregatedModel) ].

	newEntity := anEntity class new
		             name: anEntity name;
		             isStub: anEntity isStub.

	dict associationsDo: [ :assoc | 
		newEntity
			perform: (self computeSetterFrom: assoc key)
			with: assoc value ].
	
	newEntity mooseModel: agregatedModel.
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createNamespaces [

	self originModel allModelNamespaces do: [ :ns | 
		 self createEntityFrom: ns ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createPackages [

	self originModel allPackages do: [ :pkg | 
		 self createAPackage: pkg ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createStubEntityFrom: anEntity [

	| newEntity |
	newEntity := anEntity class new
		             name: anEntity name;
		             mooseModel: agregatedModel;
						isStub: true.
	anEntity parentSelectors do: [ :sel | 
		newEntity perform: (self computeSetterFrom: sel) with: (self
				 getExistingEntity: (anEntity perform: sel)
				 from: self agregatedModel) ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> getAgMethodFor: agClass [
	agClass methods ifEmpty: [ self createAgregatedMethodFor: agClass ].
	^ agClass methods anyOne.
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> getExistingEntity: anEntity from: aMooseModel [

	^ aMooseModel entityNamed: anEntity mooseName ifAbsent: [ self halt. ] 
]

{ #category : #accessing }
MooseModelAgregator >> originModel [

	^ originModel
]

{ #category : #accessing }
MooseModelAgregator >> originModel: anObject [

	originModel := anObject
]
