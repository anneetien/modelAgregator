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
		agregatedModel: (aMooseModel class named: aMooseModel name , 'Agregate')
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> acceptedChildrenOf: aPackage [

	^ aPackage children select: [ :e | 
		  e class allTraits includesAny: { 
				  FamixTPackage.
				  FamixTClass.
				  FamixTImplementable.
				  FamixTParameterizedType.
				  FamixTWithParameterizedTypes} ]
]

{ #category : #adding }
MooseModelAgregator >> addInvocation: anInvocation to: agClass [

	| agMeth candidat |
	"	1halt."
	agMeth := self getAgMethodFor: agClass.
	anInvocation candidates do: [ :cand | 
		((self isAcceptedTypeForAssociation: cand parentType) and:
		[cand parentType mooseName ~= agClass mooseName]) ifTrue: [ 
			candidat := self getAgMethodFor: (self
					           getExistingEntity: cand parentType
					           from: self agregatedModel).
			(self checkExistingInvocationSender: agMeth candidate: candidat) 
				ifFalse: [ "
			1halt."
					(self createAssociationFrom: anInvocation)
						sender: agMeth;
						addCandidate: candidat;
						signature: anInvocation signature ] ] ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> addOutgoingInvocations: invocations to: agClass [

	invocations do: [ :inv | self addInvocation: inv to: agClass ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> addReference: ref to: agClass [ 
| agMeth referredType |
	"	1halt."
	agMeth := self getAgMethodFor: agClass.
	((ref referencer parentType ~= ref referredType) and: [ ref referredType isClass or: [ ref referredType isInterface ] ] ) 
		ifTrue: [ 
			referredType := (self
					           getExistingEntity: ref referredType
					           from: self agregatedModel).
			(self checkExistingReferenceReferencer: agMeth referredType: referredType) 
				ifFalse: [ "
			1halt."
					(self createAssociationFrom: ref)
						referencer: agMeth ;
						referredType: referredType ] ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> addReferences: references to: agClass [

	references do: [ :ref | self addReference: ref to: agClass ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> addSuperInheritances: superInheritances to: agClass [
	superInheritances do: [ :supI | |inh |
		inh := (self createAssociationFrom: supI ).
		inh subclass: agClass.
		inh superclass: (self getExistingEntity: supI superclass from: self agregatedModel) ] 
	
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> agregateAClass: anOriginClass [

	| agClass invocations references |
	agClass := self
		           getExistingEntity: anOriginClass 
		           from: self agregatedModel.
	anOriginClass superInheritances ifNotEmpty: [ 
		self addSuperInheritances: anOriginClass superInheritances to: agClass ].
	invocations := anOriginClass queryOutgoing: FamixTInvocation.
	invocations ifNotEmpty: [ 
		self addOutgoingInvocations: invocations to: agClass
		 ]  .
	references := anOriginClass queryOutgoing: FamixTReference.
	references ifNotEmpty: [ 
		self addReferences: references to: agClass
		 ]  
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
MooseModelAgregator >> checkExistingInvocationSender: sender candidate: agMeth [

	^ agMeth incomingInvocations anySatisfy: [ :inv | inv sender = sender ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> checkExistingReferenceReferencer: agMeth referredType: referredType [
	^agMeth outgoingReferences anySatisfy: [ :ref | ref referredType = referredType ] 
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> computeSetterFrom: aGetter [
	^ (aGetter , ':') asSymbol
	
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
MooseModelAgregator >> createChildEntity: originChild [

	self createEntityFrom: originChild.
	(self acceptedChildrenOf: originChild) do: [ :child | 
		self createChildEntity: child ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createEntityFrom: anEntity [
"In this method, we first get the parentSelectors of the original entity. For each of these parents, we look for the corresponding entity in the new model. We create a new entity (in the new model with the same type of the original one). For this new entity we put its parents using the dictionary. The order is important because if we start by creating the entity, and if the class has the same name has the package, when we look for the entity in the new model, class and package have the same mooseName and it raises an error."
	| newEntity dict parent |
	dict := Dictionary new.
	anEntity parentSelectors do: [ :sel | 
		parent := (anEntity perform: sel).
		parent ifNotNil: [ 
		dict at: sel put: (self
				 getExistingEntity: parent
				 from: self agregatedModel)] ].

	newEntity := anEntity class new
		             isStub: anEntity isStub.
	newEntity mooseModel: agregatedModel.
	dict associationsDo: [ :assoc | 
		newEntity
			perform: (self computeSetterFrom: assoc key)
			with: assoc value.
			"assoc value resetMooseName."
			"newEntity resetMooseName."
			   ].
		newEntity name: anEntity name.
	
	
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createNamespaces [

	self originModel allModelNamespaces do: [ :ns | 
		 self createEntityFrom: ns ].
	self createRootPackages.
	(self originRootPackages flatCollect: [ :aPackage | 
		 self acceptedChildrenOf: aPackage ]) do: [ :child | 
		self createChildEntity: child ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createPackages [

	self createRootPackages.
	(self originRootPackages flatCollect: [ :aPackage | 
		 self acceptedChildrenOf: aPackage ]) do: [ :child | 
		self createChildEntity: child ]
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> createRootPackages [

	self originRootPackages do: [ :pkg | self createEntityFrom: pkg ]
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

{ #category : #'as yet unclassified' }
MooseModelAgregator >> isAcceptedTypeForAssociation: anEntity [

	^ anEntity class allTraits includesAny: { 
				  FamixTPackage.
				  FamixTClass.
				  FamixJavaInterface.}
]

{ #category : #accessing }
MooseModelAgregator >> originModel [

	^ originModel
]

{ #category : #accessing }
MooseModelAgregator >> originModel: anObject [

	originModel := anObject
]

{ #category : #'as yet unclassified' }
MooseModelAgregator >> originRootPackages [

	^ self originModel entities select: [ :e | 
		  (e class allTraits includes: FamixTPackage) and: [ e parents isEmpty ] ]
]
